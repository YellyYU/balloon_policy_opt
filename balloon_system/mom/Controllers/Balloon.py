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

import logging

class Balloon:
    """
    Simple Balloon Controller that uses the hypervisor interface to resize
    a guest's memory balloon.  Output triggers are:
        - balloon_target - Set guest balloon to this size (B)
    """
    def __init__(self, properties):
        self.hypervisor_iface = properties['hypervisor_iface']
        self.logger = logging.getLogger('mom.Controllers.Balloon')

    def process_guest(self, guest):
        target = guest.GetControl('balloon_target')
        if target is not None:
            target = int(target)
            uuid = guest.Prop('uuid')
            name = guest.Prop('name')
            prev_target = guest.Stat('balloon_cur')
            self.logger.info("Ballooning guest:%s from %s to %s", \
                    name, prev_target, target)
            self.hypervisor_iface.setVmBalloonTarget(uuid, target)

    def process(self, host, guests):
        for guest in guests:
            self.process_guest(guest)
