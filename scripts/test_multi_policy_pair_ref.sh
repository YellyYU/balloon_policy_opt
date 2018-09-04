#!/bin/bash
# created by Yelly on 13th Jan, 2018
# to run all policy test with a given pattern

wd=/home/yelly/balloon_policy_opt

momdir=$wd/balloon_system

# no policy
#sudo $run_scp $test no-policy

EXP_G=1 # number of experimental guests - to test its workload performance
SUP_G=1 # number of supporting guests - to provide additional memory
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

#pattern_map=("p2" "p20" "p100")
pattern_map=("p100")

repeat=1
workloadstep=100000
hostfreestep=52428800 # 50MB
refstep=0.3

grow_ref=.6
max_grow_ref=0.65
grow_ref_comp=`echo "$grow_ref < $max_grow_ref" | bc`
while [ $grow_ref_comp -eq 1 ]; do
	shrink_ref=.6
	max_shrink_ref=0.65
	shrink_ref_comp=`echo "$shrink_ref < $max_shrink_ref" | bc`
	while [ $shrink_ref_comp -eq 1 ]; do
		# initialize policy related...
		sudo sh $wd/scripts/init_policy_ref.sh $grow_ref $shrink_ref $interval_dir

		policydir="adpref_gref"$grow_ref"_sref"$shrink_ref
		log_policy_dir=$wd/log/$interval_dir/$policydir
		out_policy_dir=$wd/out/$interval_dir/$policydir
	
		workload=150000 # workload used by mallocRand (in kB)
		maxworkload=150000
		while [ "$workload" -le "$maxworkload" ]; do
			hostfree=0 # supposed host free memory eligible for balloong (in Bytes)
			#maxhostfree=$(( workload * 1000 ))
			maxhostfree=0
			while [ "$hostfree" -le "$maxhostfree" ]; do
				#i=1
				#while [ "$i" -le "$repeat" ]; do
				for data in ${pattern_map[@]}; do
					testname="begin"$exp_begin$sup_begin"_host"$hostfree"_load"$workload"_"${data}
					logfile=$log_policy_dir"/log_"$testname".txt"
					outdir=$out_policy_dir"/"$testname

					sudo sh $wd/scripts/init_test_ref.sh $EXP_G $SUP_G $hostfree ${data} $logfile $outdir

					heretime=`date "+%H%M05" -d "+2 min"`
					echo "heretime: $heretime" >> $logfile
#					heremomtime=`date "+%H%M00" -d "+2 min"`
					heremomtime=`date "+%H%M15" -d "+2 min"`
					echo "heremomtime: $heremomtime" >> $logfile
					starttime=`date "+%H:%M:05" -d "-8 hour"`
					starttime=`date "+%H%M05" -d "+2 minute2018-03-08 ${starttime}"`
					echo "starttime: $starttime" >> $logfile

					sudo bash $wd/scripts/run_autoballoon.sh $EXP_G $SUP_G $starttime $workload $exp_begin $sup_begin
					sh $wd/scripts/wait.sh $heremomtime

					taskset -c 0,1 sudo python $momdir/momd -c $momdir/mom-balloon.conf -r $momdir/rules/opt_select.rules &
					sh $wd/scripts/wait.sh $heretime
	
					sleep 250

					#kill -n 2 $(pgrep qemu)
					kill -2 $(pgrep qemu)
					sudo pkill -9 -f momd

					echo test_round_finished, start collect result
					sh $wd/scripts/collect_pair.sh $EXP_G $SUP_G $outdir

					#i=$(( i + 1 ))
				done
	
				hostfree=$(( hostfree + hostfreestep))
			done
			workload=$(( workload + workloadstep))
		done
		shrink_ref=`echo "$shrink_ref + $refstep" | bc`
		shrink_ref_comp=`echo "$shrink_ref < $max_shrink_ref" | bc`
	done
	grow_ref=`echo "$grow_ref + $refstep" | bc`
	grow_ref_comp=`echo "$grow_ref < $max_grow_ref" | bc`
done
echo "all tests finished!~~"
