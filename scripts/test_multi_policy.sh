#!/bin/bash
# created by Yelly on 13th Jan, 2018
# to run all policy test with a given pattern

wd=/home/yelly/balloon_policy_opt

momdir=$wd/balloon_system

# no policy
#sudo $run_scp $test no-policy

EXP_G=1 # number of experimental guests - to test its workload performance
SUP_G=0 # number of supporting guests - to provide additional memory

sed -i "67c guest-number: $(( EXP_G + SUP_G ))" $momdir/mom-balloon.conf

repeat=1 # repeat times for each test case
workloadstep=50000
hostfreestep=50000000
thresholdstep=0.1
stepstep=5000000

grow_threshold=0.9
max_grow_threshold=0.95
grow_threshold_comp=`echo "$grow_threshold < $max_grow_threshold" | bc`
while [ $grow_threshold_comp -eq 1 ]; do
	shrink_threshold=0.3
	max_shrink_threshold=0.4
	shrink_threshold_comp=`echo "$shrink_threshold < $max_shrink_threshold" | bc`
	while [ $shrink_threshold_comp -eq 1 ]; do
		grow_step=1000000
		shrink_step=1000000
		max_grow_step=46000000
		max_shrink_step=46000000
		while [ "$grow_step" -le "$max_grow_step" ]; do
			# initialize policy related...
			sudo sh $wd/scripts/init_policy.sh $grow_threshold $shrink_threshold $grow_step $shrink_step

			policydir="gth"$grow_threshold"_sth"$shrink_threshold"_gst"$grow_step"_sst"$shrink_step
			log_policy_dir=$wd/log/testopt/$policydir
			out_policy_dir=$wd/out/testopt/$policydir

			workload=50000 # workload used by mallocRand (in kB)
			maxworkload=250000
			while [ "$workload" -le "$maxworkload" ]; do
				hostfree=50000000 # supposed host free memory eligible for balloong (in Bytes)
				maxhostfree=$(( workload * 1000 ))
				while [ "$hostfree" -le "$maxhostfree" ]; do
					i=1
					while [ "$i" -le "$repeat" ]; do
						testname="host"$hostfree"_load"$workload"_rep"$i
						logfile=$log_policy_dir"/log_"$testname".txt"
						outdir=$out_policy_dir"/"$testname

						sudo sh $wd/scripts/init_test.sh $EXP_G $SUP_G $hostfree steady $logfile $outdir

						heretime=`date "+%H%M05" -d "+2 min"`
						echo "heretime: $heretime" >> $logfile
						heremomtime=`date "+%H%M00" -d "+2 min"`
						echo "heremomtime: $heremomtime" >> $logfile
						starttime=`date "+%H:%M:05" -d "-8 hour"`
						starttime=`date "+%H%M05" -d "+2 minute2018-03-08 ${starttime}"`
						echo "starttime: $starttime" >> $logfile

						sudo bash $wd/scripts/run_autoballoon.sh $EXP_G $SUP_G $starttime $workload
						sh $wd/scripts/wait.sh $heremomtime

						taskset -c 0,1 sudo python $momdir/momd -c $momdir/mom-balloon.conf -r $momdir/rules/testopt.rules &
						sh $wd/scripts/wait.sh $heretime

						sleep 270

						#kill -n 2 $(pgrep qemu)
						kill -2 $(pgrep qemu)
						sudo pkill -9 -f momd

						echo test_round_finished, start collect result
						sh $wd/scripts/collect.sh $EXP_G $outdir

						i=$(( i + 1 ))
					done
	
					hostfree=$(( hostfree + hostfreestep))
				done
				workload=$(( workload + workloadstep))
			done
			grow_step=$(( grow_step + stepstep))
			shrink_step=$(( shrink_step + stepstep))
		done
		shrink_threshold=`echo "$shrink_threshold + $thresholdstep" | bc`
		shrink_threshold_comp=`echo "$shrink_threshold < $max_shrink_threshold" | bc`
	done
	grow_threshold=`echo "$grow_threshold + $thresholdstep" | bc`
	grow_threshold_comp=`echo "$grow_threshold < $max_grow_threshold" | bc`
done
echo "all tests finished!~~"
