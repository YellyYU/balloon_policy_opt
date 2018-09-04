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

#interval_dir="testopt_collect"$collect_interval"_policy"$policy_interval

#pattern_map=("mix_workload_p20", "mix_workload_p100")
pattern_map=("mix_workload_slop_p40_125")

#initialize policy related...
# create (new) policy directory
log_policy_dir=$wd/log/opt/opt
out_policy_dir=$wd/out/opt/opt
#sudo rm -rf $log_policy_dir
#sudo rm -rf $out_policy_dir
mkdir $log_policy_dir
mkdir $out_policy_dir

for data in ${pattern_map[@]}; do
	testname=${data}
	logfile=$log_policy_dir"/log_"$testname".txt"
	outdir=$out_policy_dir"/"$testname

	sudo sh $wd/scripts/init_test_mix.sh $EXP_G $SUP_G ${data} $logfile $outdir

	heretime=`date "+%H%M05" -d "+2 min"`
	echo "heretime: $heretime" >> $logfile
	#heremomtime=`date "+%H%M00" -d "+2 min"`
	#echo "heremomtime: $heremomtime" >> $logfile
	starttime=`date "+%H:%M:05" -d "-8 hour"`
	starttime=`date "+%H%M05" -d "+2 minute2018-03-08 ${starttime}"`
	echo "starttime: $starttime" >> $logfile

	sudo bash $wd/scripts/run_autoballoon_mix.sh $EXP_G $SUP_G $starttime
	sh $wd/scripts/wait.sh $heretime

	# policy initialization
	parameter_file=/home/yelly/balloon_policy_opt/balloon_system/rules_command/parameters.txt
	sed -i "1c ref" $parameter_file
	sed -i "6,9c ref_grow_threshold: 0.9\nref_shrink_threshold: 0.3\nref_grow_ref: 0.9\nref_shrink_ref: 0.3" $parameter_file

	taskset -c 0,1 sudo python $momdir/momd -c $momdir/mom-balloon.conf -r $momdir/rules/opt_select.rules &

	# mind that in init process of tinyD, guest sleep for 10 secs after starttime
	# this ensures that MOM runs BEFORE the workload starts.
	# thus there's no need to define another mom-begin-time!
	sleep 10

	sh $wd/scripts/change_policy.sh  >> $logfile &
	sleep 1900

	#kill -n 2 $(pgrep qemu)
	kill -2 $(pgrep qemu)
	sudo pkill -9 -f momd
	sudo pkill -9 -f change_policy 

	echo test_round_finished, start collect result
	sh $wd/scripts/collect_pair.sh $EXP_G $SUP_G $outdir
done
echo "all tests finished!~~"
