#!/bin/bash
# created by Yelly on 13th Jan, 2018
# to run all policy test with a given pattern

wd=/home/yelly/balloon_policy_opt

momdir=$wd/balloon_system

# no policy
#sudo $run_scp $test no-policy

EXP_G=1 # number of experimental guests - to test its workload performance
SUP_G=0 # number of supporting guests - to provide additional memory
repeat=1 # repeat times for each test case

workloadstep=50000
hostfreestep=50000000
refstep=0.1

ref=0.8
max_ref=0.95
ref_comp=`echo "$ref < $max_ref" | bc`
while [ $ref_comp -eq 1 ]; do
	# create (new) policy directory
	policydir=ref$ref
	log_policy_dir=$wd"/log/testopt/"$policydir
	out_policy_dir=$wd"/out/testopt/"$policydir
	mkdir $log_policy_dir
	mkdir $out_policy_dir

	workload=150000 # workload used by mallocRand (in kB)
	maxworkload=250000
	while [ "$workload" -le "$maxworkload" ]; do
		hostfree=0 # supposed host free memory eligible for balloong (in Bytes)
		maxhostfree=$(( workload * 1000 ))
		while [ "$hostfree" -le "$maxhostfree" ]; do
			i=1
			while [ "$i" -le "$repeat" ]; do
				testname="host"$hostfree"_load"$workload"_rep"$i
				logfile=$log_policy_dir"/log_"$testname".txt"
				outdir=$out_policy_dir"/"$testname

				sudo sh $wd/scripts/init_ref.sh $EXP_G $SUP_G $hostfree $testname $ref
				heretime=`date "+%H%M05" -d "+2 min"`
				echo "heretime: $heretime" >> $logfile
				heremomtime=`date "+%H%M00" -d "+2 min"`
				echo "heremomtime: $heremomtime" >> $logfile
				starttime=`date "+%H:%M:05" -d "-8 hour"`
				starttime=`date "+%H%M05" -d "+2 minute2018-03-08 ${starttime}"`
				echo "starttime: $starttime" >> $logfile

				sudo bash $wd/scripts/run_autoballoon.sh $EXP_G $SUP_G $starttime $workload
				sh $wd/scripts/wait.sh $heremomtime

				taskset -c 0,1 sudo python $momdir/momd -c $momdir/mom-balloon.conf -r $momdir/rules/testopt_refp.rules &
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
	ref=`echo "$ref + $refstep" | bc`
	ref_comp=`echo "$ref < $max_ref" | bc`
done
echo "all tests finished!~~"
