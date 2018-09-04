# Memory Overcommitment Manager
# Copyright (C) 2010 Adam Litke, IBM Corporation
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

import os

class EntityError(Exception):
    pass

class Entity:
    """
    An entity is an object that is designed to be inserted into the rule-
    processing namespace.  The properties and statistics elements allow it to
    contain a snapshot of Monitor data that can be used as inputs to rules.  The
    rule-accessible methods provide a simple syntax for referencing data.
    """
    def __init__(self, monitor=None):
        self.properties = {}
        self.variables = {}
        self.statistics = []
        self.controls = {}
        self.monitor = monitor

    def _set_property(self, name, val):
        self.properties[name] = val

    def _set_variable(self, name, val):
        self.variables[name] = val

    def _set_statistics(self, stats):
        for row in stats:
            self.statistics.append(row)

    def _store_variables(self):
        """
        Pass rule-defined variables back to the Monitor for storage
        """
        if self.monitor is not None:
            self.monitor.update_variables(self.variables)

    def _finalize(self):
        """
        Once all data has been added to the Entity, perform any extra processing
        """
        # Add the most-recent stats to the top-level namespace for easy access
        # from within rules scripts.
        if len(self.statistics) > 0:
            for stat in self.statistics[-1].keys():
                if stat in self.monitor.valid_fields:
                    setattr(self, stat, self.statistics[-1][stat])
                else:
                    self.monitor.logger.debug("Field '%s' not known. Ignoring." % stat)

    def _disp(self, name=''):
        """
        Debugging function to display the structure of an Entity.
        """
        prop_str = ""
        stat_str = ""
        for i in self.properties.keys():
            prop_str = prop_str + " " + i

        if len(self.statistics) > 0:
            for i in self.statistics[0].keys():
                stat_str = stat_str + " " + i
        else:
            stat_str = ""
        print "Entity: %s {" % name
        print "    properties = { %s }" % prop_str
        print "    statistics = { %s }" % stat_str
        print "}"

    ### Rule-accesible Methods
    def Prop(self, name):
        """
        Get the value of a single property
        """
        return self.properties[name]

    def Stat(self, name, default=None):
        """
        Get the most-recently recorded value of a statistic
        Returns None if no statistics are available
        """
        if name not in self.monitor.valid_fields:
            raise KeyError("Field '%s' is not declared in any collector." % name)

        if len(self.statistics) > 0:
            return self.statistics[-1].get(name, default)
        else:
            return None

    def StatAvg(self, name):
        """
        Calculate the average value of a statistic using all recent values.
        """
        if name not in self.monitor.valid_fields:
            raise KeyError("Field '%s' is not declared in any collector." % name)

        if (len(self.statistics) == 0):
            raise EntityError("Statistic '%s' not available" % name)

        total = 0
        nonEmptyStats = [x for x in self.statistics \
                         if x.get(name, None) is not None]
        for row in nonEmptyStats:
            total = total + row[name]
        if (len(nonEmptyStats) == 0):
            return float(0)
        else:
            return float(total / len(nonEmptyStats))
    # add by Dd
    def Dd_command(self, name):
        tmp = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/'+str(name)).read()
        #self.monitor.logger.info("Dd_command, read(host_pressure) result: %f" % float(tmp))
        return float(tmp)
    def Dd_command2(self, name,value):
        tmp = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/'+str(name)+' '+str(value)).read()
        print float(tmp)
        return float(tmp)


    def SetVar(self, name, val):
        """
        Store a named value in this Entity.
        """
        self.variables[name] = val

    def GetVar(self, name):
        """
        Get the value of a potential variable in this instance.
        Returns None if the variable has not been defined.
        """
        if name in self.variables:
            return self.variables[name]
        else:
            return None

    def Control(self, name, val):
        """
        Set a control variable in this instance.
        """
        self.controls[name] = val

    def GetControl(self, name):
        """
        Get the value of a control variable in this instance if it exists.
        Returns None if the control has not been set.
        """
        if name in self.controls:
            return self.controls[name]
        else:
            return None
    #### Following are auto-ballooning policy, implemted by Dd

    ## Policy 1, Ovirt, example ballonning algorithm
    def Dd_policy1_grow(self):
        host_pressure = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/get_hostpressure').read()
        host_pressure= float(host_pressure)
        self.monitor.logger.info("read hostfree: %f" % host_pressure)
        if (self.balloon_cur < self.balloon_max):
            guest_used_mem = self.StatAvg("balloon_cur") - self.StatAvg("mem_unused")
            balloon_min = guest_used_mem + 0.2* self.balloon_cur
            balloon_size = self.balloon_cur * 1.05
            balloon_size = max(balloon_size, balloon_min)
            balloon_size = min(balloon_size, self.balloon_max)
            self.monitor.logger.info("proposed balloon size: %f" % balloon_size)
            new_hostpressure = host_pressure - (balloon_size - self.balloon_cur)
            if (new_hostpressure > 0 ):
                self.Control("balloon_target",balloon_size)
                tmp = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/set_hostpressure '+str(new_hostpressure)).read()
                self.monitor.logger.info("set hostfree: %f" % new_hostpressure)
        return 1
    def Dd_policy1_shrink(self):
        host_pressure = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/get_hostpressure').read()
        host_pressure= float(host_pressure)
        self.monitor.logger.info("read hostfree: %f" % host_pressure)
        guest_used_mem = self.StatAvg("balloon_cur") - self.StatAvg("mem_unused")
        balloon_min = guest_used_mem + 0.2* self.balloon_cur
        balloon_size = self.balloon_cur * 0.95
        balloon_size = max(balloon_size, balloon_min)
        self.monitor.logger.info("proposed balloon size: %f" % balloon_size)
        if balloon_size < self.balloon_cur:
            self.Control("balloon_target",balloon_size)
            new_hostpressure = host_pressure - (balloon_size - self.balloon_cur)
            tmp = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/set_hostpressure '+str(new_hostpressure)).read()
            self.monitor.logger.info("set hostfree: %f" % new_hostpressure)
        return 1
    def Dd_policy1(self, hostpressure, guest):
        name = guest.Prop("name")
        self.monitor.logger.info("%s -- balloon_cur: %d" % (name, self.balloon_cur))
	self.monitor.logger.info("%s -- swap_in: %d, swap_out: %d" % (name, int(self.swap_in), int(self.swap_out)))
        if hostpressure < 100:
            self.Dd_policy1_shrink()
        else:
            self.Dd_policy1_grow()
        return 1

    ## Policy 2, KVM autoballooning, most difference is change with a fixed pages
    def Dd_policy2_grow(self):
        host_pressure = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/get_hostpressure').read()
        host_pressure= float(host_pressure)
        self.monitor.logger.info("read hostfree: %f" % host_pressure)
        if (self.balloon_cur < self.balloon_max):
            guest_used_mem = self.StatAvg("balloon_cur") - self.StatAvg("mem_unused")
            balloon_size = self.balloon_cur + 4096*1000 ## add 100 pages per operation
            balloon_max  = guest_used_mem / 0.5
            balloon_size = min(balloon_size, balloon_max)
            self.monitor.logger.info("proposed balloon size: %f" % balloon_size)
            new_hostpressure = host_pressure - (balloon_size - self.balloon_cur)
            if new_hostpressure > 0:
                self.Control("balloon_target",balloon_size)
                tmp = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/set_hostpressure '+str(new_hostpressure)).read()
                self.monitor.logger.info("set hostfree: %f" % new_hostpressure)
        return 1
    def Dd_policy2_shrink(self):
        host_pressure = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/get_hostpressure').read()
        host_pressure= float(host_pressure)
        self.monitor.logger.info("read hostfree: %f" % host_pressure)
        guest_used_mem = self.StatAvg("balloon_cur") - self.StatAvg("mem_unused")
        balloon_min = guest_used_mem + 0.2* self.balloon_cur
        balloon_size = self.balloon_cur - 4096*1000 ## remove 1000 pages per operation
        balloon_size = max(balloon_size,balloon_min) ## do not change current memory is hard
        self.monitor.logger.info("proposed balloon size: %f" % balloon_size)
        if balloon_size < self.balloon_cur:
            self.Control("balloon_target",balloon_size)
            new_hostpressure = host_pressure - (balloon_size - self.balloon_cur)
            tmp = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/set_hostpressure '+str(new_hostpressure)).read()
            self.monitor.logger.info("set hostfree: %f" % new_hostpressure)
        return 1
    def Dd_policy2(self, hostpressure, guest):
        name = guest.Prop("name")
        self.monitor.logger.info("%s -- balloon_cur: %d" % (name, self.balloon_cur))
	self.monitor.logger.info("%s -- swap_in: %d, swap_out: %d" % (name, int(self.swap_in), int(self.swap_out)))
        if hostpressure < 100:
            self.Dd_policy2_shrink()
        else:
            self.Dd_policy2_grow()
        return 1

    ## Policy 3, xenserver dynamic memory control
    def Dd_policy3_grow(self):
        host_pressure = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/get_hostpressure').read()
        host_pressure= float(host_pressure)
        self.monitor.logger.info("read hostfree: %f" % host_pressure)
        balloon_size = self.balloon_cur * 1.05
        balloon_size = min(balloon_size, self.balloon_max)
        self.monitor.logger.info("proposed balloon size: %f" % balloon_size)
        new_hostpressure = host_pressure - (balloon_size - self.balloon_cur)
        if (new_hostpressure > 0):
            self.Control("balloon_target",balloon_size)
            tmp = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/set_hostpressure '+str(new_hostpressure)).read()
            self.monitor.logger.info("set hostfree: %f" % new_hostpressure)
        return 1
    def Dd_policy3_shrink(self):
        host_pressure = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/get_hostpressure').read()
        host_pressure= float(host_pressure)
        self.monitor.logger.info("read hostfree: %f" % host_pressure)
        balloon_size = self.balloon_cur * 0.95
        balloon_size = max(balloon_size, self.balloon_min)
        self.monitor.logger.info("proposed balloon size: %f" % balloon_size)
        if balloon_size < self.balloon_cur:
            self.Control("balloon_target",balloon_size)
            new_hostpressure = host_pressure - (balloon_size - self.balloon_cur)
            tmp = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/set_hostpressure '+str(new_hostpressure)).read()
            self.monitor.logger.info("set hostfree: %f" % new_hostpressure)
        return 1
    def Dd_policy3(self, hostpressure, guest):
        name = guest.Prop("name")
        self.monitor.logger.info("%s -- balloon_cur: %d" % (name, self.balloon_cur))
	self.monitor.logger.info("%s -- swap_in: %d, swap_out: %d" % (name, int(self.swap_in), int(self.swap_out)))
        if hostpressure < 100:
            self.Dd_policy3_shrink()
        else:
            self.Dd_policy3_grow()
        return 1

    ## Policy 4, Dynamic Memory allocation Controller
    def Dd_policy4_apply(self):
        host_pressure = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/get_hostpressure').read()
        host_pressure= float(host_pressure)
        self.monitor.logger.info("read hostfree: %f" % host_pressure)
        guest_used_mem = self.StatAvg("balloon_cur") - self.StatAvg("mem_unused")
        used_percent = float(guest_used_mem) / self.StatAvg("balloon_cur")
        ref_percent = 0.8
        balloon_size = self.balloon_cur - guest_used_mem*(ref_percent - used_percent)/ref_percent
        balloon_size = max(balloon_size, self.balloon_min)
        balloon_size = min(balloon_size, self.balloon_max)
        self.monitor.logger.info("proposed balloon size: %f" % balloon_size)
        if balloon_size < self.balloon_cur:
            self.Control("balloon_target",balloon_size)
            new_hostpressure = host_pressure - (balloon_size - self.balloon_cur)
            tmp = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/set_hostpressure '+str(new_hostpressure)).read()
            self.monitor.logger.info("set hostfree: %f" % new_hostpressure)
        else:
            new_hostpressure = host_pressure - (balloon_size - self.balloon_cur)
            if new_hostpressure >0:
                self.Control("balloon_target",balloon_size)
                tmp = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/set_hostpressure '+str(new_hostpressure)).read()
                self.monitor.logger.info("set hostfree: %f" % new_hostpressure)
        return 1
    def Dd_policy4(self, hostpressure, guest):
        name = guest.Prop("name")
        self.monitor.logger.info("%s -- balloon_cur: %d" % (name, self.balloon_cur))
	self.monitor.logger.info("%s -- swap_in: %d, swap_out: %d" % (name, int(self.swap_in), int(self.swap_out)))
        self.Dd_policy4_apply()
        return 1

    ## Policy 5, Wei-Zhe Zhang: self-scheduling && local feedbackloop
    def Dd_policy5_apply(self):
        host_pressure = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/get_hostpressure').read()
        host_pressure= float(host_pressure)
        self.monitor.logger.info("read hostfree: %f" % host_pressure)
        guest_used_mem = self.StatAvg("balloon_cur") - self.StatAvg("mem_unused")
        ref_percent = 0.7
        balloon_size = guest_used_mem / ref_percent #self.balloon_cur - guest_used_mem*(ref_percent - used_percent)/ref_percent
        self.monitor.logger.info("self.StatAvg(balloon_cur): %d, guest_used_mem: %d" % (self.StatAvg("balloon_cur"), guest_used_mem))
        balloon_size = max(balloon_size, self.balloon_min)
        balloon_size = min(balloon_size, self.balloon_max)
        self.monitor.logger.info("proposed balloon size: %f" % balloon_size)
        if balloon_size < self.balloon_cur:
            self.Control("balloon_target",balloon_size)
            new_hostpressure = host_pressure - (balloon_size - self.balloon_cur)
            tmp = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/set_hostpressure '+str(new_hostpressure)).read()
            self.monitor.logger.info("set hostfree: %f" % new_hostpressure)
        else:
            new_hostpressure = host_pressure - (balloon_size - self.balloon_cur)
            if new_hostpressure >0:
                self.Control("balloon_target",balloon_size)
                tmp = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/set_hostpressure '+str(new_hostpressure)).read()
                self.monitor.logger.info("set hostfree: %f" % new_hostpressure)

        return 1
    def Dd_policy5(self, hostpressure, guest):
        name = guest.Prop("name")
        self.monitor.logger.info("%s -- balloon_cur: %d" % (name, self.balloon_cur))
	self.monitor.logger.info("%s -- swap_in: %d, swap_out: %d" % (name, int(self.swap_in), int(self.swap_out)))
        self.Dd_policy5_apply()
        return 1

    ## Policy 6, Hyper-V dynamic memory
    def Dd_policy6_apply(self):
        host_pressure = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/get_hostpressure').read()
        host_pressure= float(host_pressure)
	self.monitor.logger.info("read hostfree: %f" % host_pressure)
        guest_used_mem = self.StatAvg("balloon_cur") - self.StatAvg("mem_unused")
        used_percent = float(guest_used_mem) / self.StatAvg("balloon_cur")
        ref_percent = 0.7
        balloon_size = guest_used_mem / ref_percent #self.balloon_cur - guest_used_mem*(ref_percent - used_percent)/ref_percent
        balloon_size = max(balloon_size, self.balloon_min)
        balloon_size = min(balloon_size, self.balloon_max)
        self.monitor.logger.info("proposed balloon size: %f" % balloon_size)
        if balloon_size < self.balloon_cur:
            if host_pressure <100:
                self.Control("balloon_target",balloon_size)
                new_hostpressure = host_pressure - (balloon_size - self.balloon_cur)
                tmp = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/set_hostpressure '+str(new_hostpressure)).read()
                self.monitor.logger.info("set hostfree: %f" % new_hostpressure)
        else:
            balloon_size = self.balloon_cur + 4096*1000 # static allocate 1000 pages to the guest
            new_hostpressure = host_pressure - (balloon_size - self.balloon_cur)
            if new_hostpressure > 0:
                self.Control("balloon_target",balloon_size)
                tmp = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/set_hostpressure '+str(new_hostpressure)).read()
                self.monitor.logger.info("set hostfree: %f" % new_hostpressure)

        return 1
    def Dd_policy6(self, hostpressure, guest):
        name = guest.Prop("name")
        self.monitor.logger.info("%s -- balloon_cur: %d" % (name, self.balloon_cur))
	self.monitor.logger.info("%s -- swap_in: %d, swap_out: %d" % (name, int(self.swap_in), int(self.swap_out)))
        self.Dd_policy6_apply()
        return 1

    ## Policy 7, U-tube, currently we cannot have the information about swap usage, and to count the page faults number is also not such simple, levave it to further evaluation
    ## [TODO] add swap information in the algorithm and add page faults numbers as one of check conditions
    def Dd_policy7_apply(self):
        #self.monitor.logger.info("Evaluating Dd_policy7_apply(U-tube)...")
        host_pressure = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/get_hostpressure').read()
        #self.monitor.logger.info("shrinking guest...")
        host_pressure= float(host_pressure)
	self.monitor.logger.info("read hostfree: %f" % host_pressure)
        page_faults_grow_enough = 0 ## now, we will not check the stats of page faults
        guest_swap_used = 0 ## now, we do not consider about swap usage
        guest_used_mem = self.StatAvg("balloon_cur") - self.StatAvg("mem_unused") + guest_swap_used
        used_percent = float(guest_used_mem) / self.StatAvg("balloon_cur")
        ref_percent = 0.9
        acceptable_percent=0.8
        balloon_size = guest_used_mem / acceptable_percent #self.balloon_cur - guest_used_mem*(ref_percent - used_percent)/ref_percent
        balloon_size = max(balloon_size, self.balloon_min)
        balloon_size = min(balloon_size, self.balloon_max)
        self.monitor.logger.info("U-tube, proposed balloon_size:%d" % balloon_size)
        if balloon_size < self.balloon_cur:
            #self.monitor.logger.info("U-tube, shrinking...")
            if host_pressure <100:
                #self.monitor.logger.info("U-tube, host_pressure<0...")
                self.Control("balloon_target",balloon_size)
                new_hostpressure = host_pressure - (balloon_size - self.balloon_cur)
                tmp = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/set_hostpressure '+str(new_hostpressure)).read()
                self.monitor.logger.info("set hostfree: %f" % new_hostpressure)
                #self.monitor.logger.info("U-tube, shrinking finished")
        else:
            #self.monitor.logger.info("U-tube, growing...")
            new_hostpressure = host_pressure - (balloon_size - self.balloon_cur)
            if (new_hostpressure >0 and used_percent>ref_percent) or (page_faults_grow_enough ==1):
                #self.monitor.logger.info("growing guest...")
                self.Control("balloon_target",balloon_size)
                tmp = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/set_hostpressure '+str(new_hostpressure)).read()
                self.monitor.logger.info("set hostfree: %f" % new_hostpressure)
                #self.monitor.logger.info("U-tube, shrinking finshed.")

        return 1
    def Dd_policy7(self, hostpressure, guest):
        name = guest.Prop("name")
        self.monitor.logger.info("%s -- balloon_cur: %d" % (name, self.balloon_cur))
	self.monitor.logger.info("%s -- swap_in: %d, swap_out: %d" % (name, int(self.swap_in), int(self.swap_out)))
        self.Dd_policy7_apply()
        return 1

    ## Policy 8, iBalloon
    def Dd_policy8_shrink_normal(self, guest):
        name = guest.Prop("name")
        self.monitor.logger.info("%s -- balloon_cur: %d" % (name, self.balloon_cur))
	self.monitor.logger.info("%s -- swap_in: %d, swap_out: %d" % (name, int(self.swap_in), int(self.swap_out)))
        host_pressure = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/get_hostpressure').read()
        host_pressure= float(host_pressure)
	self.monitor.logger.info("read hostfree: %f" % host_pressure)
        guest_used_mem = self.StatAvg("balloon_cur") - self.StatAvg("mem_unused")
        used_percent = float(guest_used_mem) / self.StatAvg("balloon_cur")
        if used_percent > 0.3:
            return 0
        balloon_size = guest_used_mem / 0.5
        balloon_size = min(balloon_size, self.balloon_max)
        balloon_size = max(balloon_size, self.balloon_min)
        self.monitor.logger.info("iballoon, shrink_normal, self.balloon_cur: %d, self.StatAvg(balloon_cur): %d, mem_unused: %d, used_percent: %f, proposed balloon size: %f" % (self.balloon_cur, self.StatAvg("balloon_cur"), self.mem_unused, used_percent, balloon_size))
        new_hostpressure = host_pressure - (balloon_size - self.balloon_cur)
        if new_hostpressure > 0:
            self.Control("balloon_target",balloon_size)
            tmp = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/set_hostpressure '+str(new_hostpressure)).read()
            self.monitor.logger.info("set hostfree: %f" % new_hostpressure)
        return 1
    def Dd_policy8_grow_critical(self):
        host_pressure = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/get_hostpressure').read()
        host_pressure= float(host_pressure)
	self.monitor.logger.info("read hostfree: %f" % host_pressure)
        guest_used_mem = self.StatAvg("balloon_cur") - self.StatAvg("mem_unused")
        used_percent = float(guest_used_mem) / self.StatAvg("balloon_cur")
        if used_percent < 0.9:
            return 0
        balloon_size = guest_used_mem / 0.7
        balloon_size = min(balloon_size, self.balloon_max)
        balloon_size = max(balloon_size, self.balloon_min)
        self.monitor.logger.info("iballoon, grow_critical, self.balloon_cur: %d, self.StatAvg(balloon_cur): %d, mem_unused: %d, used_percent: %f, proposed balloon size: %f" % (self.balloon_cur, self.StatAvg("balloon_cur"), self.mem_unused, used_percent, balloon_size))
        new_hostpressure = host_pressure - (balloon_size - self.balloon_cur)
        if new_hostpressure > 0:
            self.Control("balloon_target",balloon_size)
            tmp = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/set_hostpressure '+str(new_hostpressure)).read()
            self.monitor.logger.info("set hostfree: %f" % new_hostpressure)
        return 1
    def Dd_policy8_grow_warn(self):
        host_pressure = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/get_hostpressure').read()
        host_pressure= float(host_pressure)
	self.monitor.logger.info("read hostfree: %f" % host_pressure)
        guest_used_mem = self.StatAvg("balloon_cur") - self.StatAvg("mem_unused")
        used_percent = float(guest_used_mem) / self.StatAvg("balloon_cur")
        if used_percent > 0.9 or used_percent<0.3 or host_pressure<0:
            return 0
        balloon_size = guest_used_mem / 0.7
        balloon_size = max(balloon_size, self.balloon_cur)
        balloon_size = min(balloon_size, self.balloon_max)
        self.monitor.logger.info("iballoon, grow_warn, self.balloon_cur: %d, self.StatAvg(balloon_cur): %d, mem_unused: %d, used_percent: %f, proposed balloon size: %f" % (self.balloon_cur, self.StatAvg("balloon_cur"), self.mem_unused, used_percent, balloon_size))
        new_hostpressure = host_pressure - (balloon_size - self.balloon_cur)
        if balloon_size > self.balloon_cur and new_hostpressure > 0:
            self.Control("balloon_target",balloon_size)
            tmp = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/set_hostpressure '+str(new_hostpressure)).read()
            self.monitor.logger.info("set hostfree: %f" % new_hostpressure)
        return 1
    def Dd_policy8_shrink_warn(self):
        host_pressure = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/get_hostpressure').read()
        host_pressure= float(host_pressure)
	self.monitor.logger.info("read hostfree: %f" % host_pressure)
        guest_used_mem = self.StatAvg("balloon_cur") - self.StatAvg("mem_unused")
        used_percent = float(guest_used_mem) / self.StatAvg("balloon_cur")
        if used_percent > 0.9 or used_percent<0.3 or host_pressure >0:
            return 0
        balloon_size = guest_used_mem / 0.85
        balloon_size = max(balloon_size, self.balloon_cur)
        balloon_size = min(balloon_size, self.balloon_max)
        self.monitor.logger.info("iballoon, shrink_warn, self.balloon_cur: %d, self.StatAvg(balloon_cur): %d, mem_unused: %d, used_percent: %f, proposed balloon size: %f" % (self.balloon_cur, self.StatAvg("balloon_cur"), self.mem_unused, used_percent, balloon_size))
        if balloon_size < self.balloon_cur:
            self.Control("balloon_target",balloon_size)
            new_hostpressure = host_pressure - (balloon_size - self.balloon_cur)
            tmp = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/set_hostpressure '+str(new_hostpressure)).read()
            self.monitor.logger.info("set hostfree: %f" % new_hostpressure)
        return 1
    def Dd_policy8(self, hostpressure):
        return 1

######################################## balloon_opt_policies
    def Opt_policy_prop(self, guest, name):
        return guest.Prop(name)

    def Opt_policy_print_zero(self, form):
        self.monitor.logger.info(form)
        return

    def Opt_policy_print_one(self, form, arg1):
        self.monitor.logger.info(form % arg1)
        return

    def Opt_policy_print_two(self, form, arg1, arg2):
        self.monitor.logger.info(form % (arg1, arg2))
        return

    def Opt_policy_print_three(self, form, arg1, arg2, arg3):
        self.monitor.logger.info(form % (arg1, arg2, arg3))
        return

    def Opt_policy_get_command(self, name):
        value = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/'+str(name)).read()
        self.monitor.logger.info("GET %s: %s" % (name, value))
        return float(value)

    def Opt_policy_set_command(self, name,value):
        tmp = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/'+str(name)+' '+str(value)).read()
        self.monitor.logger.info("SET %s: to %s" % (name, value))
        return float(value)

    def Opt_policy_float_divide(self, arg1, arg2):
        val = float(arg1) / float(arg2)
        return val

    def Opt_policy_float_to_int(self, arg):
        val = int(arg)
        return val

    def Opt_policy_used_percent(self, guest):
        name = guest.Prop("name")
        guest_used_mem = self.StatAvg("balloon_cur") - self.StatAvg("mem_unused")
        used_percent = float(guest_used_mem) / self.StatAvg("balloon_cur")
        self.monitor.logger.info("%s -- mem_unused: %d, used_percent: %f" % (name, self.mem_unused, used_percent))
        self.monitor.logger.info("%s -- swap_in: %d, swap_out: %d" % (name, int(self.swap_in), int(self.swap_out)))
        return used_percent

    def Opt_policy_ref_target(self, ref):
        guest_used_mem = self.StatAvg("balloon_cur") - self.StatAvg("mem_unused")
        used_percent = float(guest_used_mem) / self.StatAvg("balloon_cur")
        self.monitor.logger.info("used_percent: %f" % used_percent)
        return used_percent

    def opt_policy_threshold(self, target, hostpressure):
        target = min(self.balloon_max, target)
        target = max(self.balloon_min, target)
        return target

    def opt_policy_grow_step(self, step):
        self.monitor.logger.info("growing guest...")
        target = float(self.balloon_cur) + step
        if target > self.balloon_max:
            target = self.balloon_max

        hostpressure = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/get_hostpressure').read()
        hostpressure = float(hostpressure)
        self.monitor.logger.info("GET hostpressure: %s" % hostpressure)

        new_hostpressure = hostpressure - (target - float(self.balloon_cur))
        if new_hostpressure < 0:
            new_step = int(hostpressure) / 5242880 #5MB
            new_step = new_step * 5242880
            target = self.balloon_cur + new_step
            new_hostpressure = hostpressure - (target - float(self.balloon_cur))
        tmp = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/set_hostpressure '+str(new_hostpressure)).read()
        self.monitor.logger.info("SET hostpressure: %s" % new_hostpressure)
        self.Control("balloon_target", target)
        return 1

    def opt_policy_shrink_step(self, step):
        self.monitor.logger.info("shrinking guest...")
        target = float(self.balloon_cur) - step
        if target < self.balloon_min:
            target = self.balloon_min

        hostpressure = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/get_hostpressure').read()
        hostpressure = float(hostpressure)
        self.monitor.logger.info("GET hostpressure: %s" % hostpressure)

        new_hostpressure = hostpressure - (target - float(self.balloon_cur))
        tmp = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/set_hostpressure '+str(new_hostpressure)).read()
        self.monitor.logger.info("SET hostpressure: %s" % new_hostpressure)
        self.Control("balloon_target", target)
        return 1

    def opt_policy_step(self, guest, grow_threshold, shrink_threshold, grow_step, shrink_step):
        # read policy parameters
        self.monitor.logger.info("grow_threshold: %f, shrink_threshold: %f, grow_step: %f, shrink_step: %f" % (grow_threshold, shrink_threshold, grow_step, shrink_step))
        name = guest.Prop("name")
        self.monitor.logger.info("%s -- balloon_cur: %d" % (name, self.balloon_cur))

        # trigger
        guest_used_mem = self.StatAvg("balloon_cur") - self.StatAvg("mem_unused")
        used_percent = float(guest_used_mem) / self.StatAvg("balloon_cur")
        self.monitor.logger.info("%s -- used_percent: %f" % (name, used_percent))
        self.monitor.logger.info("%s -- swap_in: %d, swap_out: %d" % (name, int(self.swap_in), int(self.swap_out)))

        # control
        if used_percent < shrink_threshold:
            self.opt_policy_shrink_step(shrink_step)
        elif used_percent > grow_threshold:
            self.opt_policy_grow_step(grow_step)

        return 0

    def opt_policy_grow_ref(self, used_mem, ref):
        self.monitor.logger.info("growing guest...")
        target = float(used_mem) / ref
        # round to 1MB
        target = int(target) / 1048576
        target = target * 1048576
        if target > self.balloon_max:
            target = self.balloon_max

        hostpressure = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/get_hostpressure').read()
        hostpressure = float(hostpressure)
        self.monitor.logger.info("GET hostpressure: %s" % hostpressure)

        new_hostpressure = hostpressure - (target - float(self.balloon_cur))
        if new_hostpressure < 0:
            new_step = int(hostpressure) / 5242880 #5MB
            new_step = new_step * 5242880
            target = self.balloon_cur + new_step
            new_hostpressure = hostpressure - (target - float(self.balloon_cur))
        tmp = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/set_hostpressure '+str(new_hostpressure)).read()
        self.monitor.logger.info("SET hostpressure: %s" % new_hostpressure)
        self.Control("balloon_target", target)
        return 1

    def opt_policy_shrink_ref(self, used_mem, ref):
        self.monitor.logger.info("shrinking guest...")
        target = float(used_mem) / ref
        # round to 1MB
        target = int(target) / 1048576
        target = target * 1048576
        if target < self.balloon_min:
            target = self.balloon_min

        hostpressure = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/get_hostpressure').read()
        hostpressure = float(hostpressure)
        self.monitor.logger.info("GET hostpressure: %s" % hostpressure)

        new_hostpressure = hostpressure - (target - float(self.balloon_cur))
        tmp = os.popen('/home/yelly/balloon_policy_opt/balloon_system/rules_command/set_hostpressure '+str(new_hostpressure)).read()
        self.monitor.logger.info("SET hostpressure: %s" % new_hostpressure)
        self.Control("balloon_target", target)
        return 1

    def opt_policy_ref(self, guest, grow_threshold, shrink_threshold, grow_ref, shrink_ref):
        # read policy parameters
        self.monitor.logger.info("grow_threshold: %f, shrink_threshold: %f, grow_ref: %f, shrink_ref: %f" % (grow_threshold, shrink_threshold, grow_ref, shrink_ref))

        name = guest.Prop("name")
        self.monitor.logger.info("%s -- balloon_cur: %d" % (name, self.balloon_cur))

        # trigger
        guest_used_mem = self.StatAvg("balloon_cur") - self.StatAvg("mem_unused")
        used_percent = float(guest_used_mem) / self.StatAvg("balloon_cur")
        self.monitor.logger.info("%s -- used_percent: %f" % (name, used_percent))
        self.monitor.logger.info("%s -- swap_in: %d, swap_out: %d" % (name, int(self.swap_in), int(self.swap_out)))

        # control
        if used_percent < shrink_threshold:
            self.opt_policy_shrink_ref(guest_used_mem, shrink_ref)
        elif used_percent > grow_threshold:
            self.opt_policy_grow_ref(guest_used_mem, grow_ref)

        return 0

    def opt_policy_select(self, guest):
        # read policy parameters
        f = open('/home/yelly/balloon_policy_opt/balloon_system/rules_command/parameters.txt')
        parameters = f.readlines()
        p_type = parameters[0]
        step_grow_threshold = parameters[1].split(': ')[1]
        step_grow_threshold = float(step_grow_threshold) 
        step_shrink_threshold = parameters[2].split(': ')[1]
        step_shrink_threshold = float(step_shrink_threshold) 
        step_grow_step = parameters[3].split(': ')[1]
        step_grow_step = float(step_grow_step) 
        step_shrink_step = parameters[4].split(': ')[1]
        step_shrink_step = float(step_shrink_step) 
        ref_grow_threshold = parameters[5].split(': ')[1]
        ref_grow_threshold = float(ref_grow_threshold) 
        ref_shrink_threshold = parameters[6].split(': ')[1]
        ref_shrink_threshold = float(ref_shrink_threshold) 
        ref_grow_ref = parameters[7].split(': ')[1]
        ref_grow_ref = float(ref_grow_ref) 
        ref_shrink_ref = parameters[8].split(': ')[1]
        ref_shrink_ref = float(ref_shrink_ref) 
        f.close()

        step_str="step"
        ref_str="ref"
        if step_str in p_type: 
            self.opt_policy_step(guest, step_grow_threshold, step_shrink_threshold, step_grow_step, step_shrink_step)
        elif ref_str in p_type:
            self.opt_policy_ref(guest, ref_grow_threshold, ref_shrink_threshold, ref_grow_ref, ref_shrink_ref)
        else:
            self.monitor.logger.info("unidentified policy type: %s" % p_type)

        return 0
