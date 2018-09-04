#!/bin/bash
# created by Yelly on 13th Jan, 2018
# to run all policy test with a given pattern

wd=/home/yelly/balloon_policy_opt

momdir=$wd/balloon_system

# no policy
#sudo $run_scp $test no-policy

EXP_G=1 # number of experimental guests - to test its workload performance
SUP_G=1 # number of supporting guests - in this test they're merely experimental guests with different workload pattern
sed -i "67c guest-number: $(( EXP_G + SUP_G ))" $momdir/mom-balloon.conf

collect_interval=2
policy_interval=3

# this part should be puted into init_policy.sh...
sed -i "3c main-loop-interval: $collect_interval" $momdir/mom-balloon.conf
sed -i "6c host-monitor-interval: $collect_interval" $momdir/mom-balloon.conf
sed -i "9c guest-monitor-interval: $collect_interval" $momdir/mom-balloon.conf
sed -i "19c policy-engine-interval: $policy_interval" $momdir/mom-balloon.conf

interval_dir="testopt_collect"$collect_interval"_policy"$policy_interval
#policy_map=( "U-tube" "iballoon" "Wei-Zhe_Zhang" "dynamic_memory_allocation_controller" "Hyper-V-dynamic-memory" "kvm_autoballoon" "xenserver-dynamic-memory-control" "ovirt-balloon-qos")
policy_map=("iballoon")
#pattern_map=("mix_workload_p20" "mix_workload_p100" "mix_workload_slop_p20" "mix_workload_slop_p40")
pattern_map=("p40" "p100" "slop_p40" "slop_p100")

workloadstep=25000
exp_begin=136314880
sup_begin=104857600

for policy in ${policy_map[@]}; do
	#initialize policy related...
	# create (new) policy directory
	policydir=${policy}
	log_policy_dir=$wd/log/$interval_dir/$policydir
	out_policy_dir=$wd/out/$interval_dir/$policydir
	#sudo rm -rf $log_policy_dir
	#sudo rm -rf $out_policy_dir
	mkdir $log_policy_dir
	mkdir $out_policy_dir
	workload=50000
	maxworkload=150000
	while [ "$workload" -le "$maxworkload" ]; do
		hostfree=0
		for data in ${pattern_map[@]}; do
			testname="begin"$exp_begin$sup_begin"_host"$hostfree"_load"$workload"_"${data}
			logfile=$log_policy_dir"/log_"$testname".txt"
			outdir=$out_policy_dir"/"$testname

			sudo sh $wd/scripts/init_test.sh $EXP_G $SUP_G $hostfree ${data} $logfile $outdir

			heretime=`date "+%H%M05" -d "+2 min"`
			echo "heretime: $heretime" >> $logfile
			heremomtime=`date "+%H%M00" -d "+2 min"`
			echo "heremomtime: $heremomtime" >> $logfile
			starttime=`date "+%H:%M:05" -d "-8 hour"`
			starttime=`date "+%H%M05" -d "+2 minute2018-03-08 ${starttime}"`
			echo "starttime: $starttime" >> $logfile

			sudo bash $wd/scripts/run_autoballoon.sh $EXP_G $SUP_G $starttime $workload $exp_begin $sup_begin
			sh $wd/scripts/wait.sh $heremomtime

			taskset -c 0,1 sudo python $momdir/momd -c $momdir/mom-balloon.conf -r $momdir/rules/${policy}.rules &
			sh $wd/scripts/wait.sh $heretime

			sleep 260

			#kill -n 2 $(pgrep qemu)
			kill -2 $(pgrep qemu)
			sudo pkill -9 -f momd

			echo test_round_finished, start collect result
			sh $wd/scripts/collect_pair.sh $EXP_G $SUP_G $outdir
		done
		workload=$(( workload + workloadstep ))
	done
done
echo "all tests finished!~~"
