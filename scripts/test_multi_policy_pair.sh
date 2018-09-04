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

sed -i "3c main-loop-interval: $collect_interval" $momdir/mom-balloon.conf
sed -i "6c host-monitor-interval: $collect_interval" $momdir/mom-balloon.conf
sed -i "9c guest-monitor-interval: $collect_interval" $momdir/mom-balloon.conf
sed -i "19c policy-engine-interval: $policy_interval" $momdir/mom-balloon.conf

interval_dir="testopt_collect"$collect_interval"_policy"$policy_interval

exp_begin=136314880 # 130MB
sup_begin=104857600 # 100MB
#exp_begin=94371840 # 90MB
#sup_begin=94371840 # 90MB

pattern_map=("slop_p100")
#pattern_map=("p20" "p100")

repeat=1 # repeat times for each test case
workloadstep=100000
hostfreestep=52428800 # 50MB
thresholdstep=0.2
stepstep=33554432 #32MB

grow_threshold=.7
max_grow_threshold=.75
grow_threshold_comp=`echo "$grow_threshold < $max_grow_threshold" | bc`
while [ $grow_threshold_comp -eq 1 ]; do
	shrink_threshold=.6
	max_shrink_threshold=0.65
	#max_shrink_threshold=$grow_threshold
	shrink_threshold_comp=`echo "$shrink_threshold < $max_shrink_threshold" | bc`
	while [ $shrink_threshold_comp -eq 1 ]; do
		grow_step=134217728 #128MB
		shrink_step=134217728 #128MB
		max_grow_step=134217728 #128MB
		max_shrink_step=134217728 #128MB
		#grow_step=46000000
		#shrink_step=46000000
		#max_grow_step=46000000
		#max_shrink_step=46000000
		while [ "$grow_step" -le "$max_grow_step" ]; do
			#initialize policy related...
			sudo sh $wd/scripts/init_policy.sh $grow_threshold $shrink_threshold $grow_step $shrink_step $interval_dir

			# create (new) policy directory
			policydir="adp_stp_gth"$grow_threshold"_sth"$shrink_threshold"_gst"$grow_step"_sst"$shrink_step
			log_policy_dir=$wd/log/$interval_dir/$policydir
			out_policy_dir=$wd/out/$interval_dir/$policydir
			# initialization work is done in init_policy.sh
			#sudo rm -rf $log_policy_dir
			#sudo rm -rf $out_policy_dir
			#mkdir $log_policy_dir
			#mkdir $out_policy_dir

			workload=50000 # workload used by mallocRand (in kB)
			maxworkload=150000
			while [ "$workload" -le "$maxworkload" ]; do
				hostfree=0 # supposed host free memory eligible for balloong (in Bytes)
				maxhostfree=0 # supposed host free memory eligible for balloong (in Bytes)
				#maxhostfree=$(( workload * 1000 ))
				while [ "$hostfree" -le "$maxhostfree" ]; do
					#i=1
					#while [ "$i" -le "$repeat" ]; do
					 for data in ${pattern_map[@]}; do
						testname="begin"$exp_begin$sup_begin"_host"$hostfree"_load"$workload"_"${data}
						logfile=$log_policy_dir"/log_"$testname".txt"
						outdir=$out_policy_dir"/"$testname

						sudo sh $wd/scripts/init_test.sh $EXP_G $SUP_G $hostfree ${data} $logfile $outdir

						heretime=`date "+%H%M05" -d "+2 min"`
						echo "heretime: $heretime" >> $logfile
#						heremomtime=`date "+%H%M00" -d "+2 min"`
						heremomtime=`date "+%H%M15" -d "+2 min"`
						echo "heremomtime: $heremomtime" >> $logfile
						starttime=`date "+%H:%M:05" -d "-8 hour"`
						starttime=`date "+%H%M05" -d "+2 minute2018-03-08 ${starttime}"`
						echo "starttime: $starttime" >> $logfile

						sudo bash $wd/scripts/run_autoballoon.sh $EXP_G $SUP_G $starttime $workload $exp_begin $sup_begin
						sh $wd/scripts/wait.sh $heremomtime

						taskset -c 0,1 sudo python $momdir/momd -c $momdir/mom-balloon.conf -r $momdir/rules/opt_select.rules &
						sh $wd/scripts/wait.sh $heretime

						sleep 260

						#kill -n 2 $(pgrep qemu)
						kill -2 $(pgrep qemu)
						sudo pkill -9 -f momd

						echo test_round_finished, start collect result
						sh $wd/scripts/collect_pair.sh $EXP_G $SUP_G $outdir
					done
	
					hostfree=$(( hostfree + hostfreestep ))
				done
				workload=$(( workload + workloadstep ))
			done
			grow_step=$(( grow_step + stepstep ))
			shrink_step=$(( shrink_step + stepstep ))
		done
		shrink_threshold=`echo "$shrink_threshold + $thresholdstep" | bc`
		shrink_threshold_comp=`echo "$shrink_threshold < $max_shrink_threshold" | bc`
	done
	grow_threshold=`echo "$grow_threshold + $thresholdstep" | bc`
	grow_threshold_comp=`echo "$grow_threshold < $max_grow_threshold" | bc`
done
echo "all tests finished!~~"
