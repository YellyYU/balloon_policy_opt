#!/bin/bash

result_dir=/home/yelly/balloon_policy_opt/out/testopt

finish_mark=finished
entry_mark=Done
entry_num=100

outputfile=/home/yelly/balloon_policy_opt/analysis/analysis_result_$(date +'%m%d-%H%M').csv
# delete existing output file
rm -f $outputfile

for policy in `ls $result_dir`
do
	if echo $policy | grep 'gth'
	#if echo $policy | grep 'ref'
	then
		echo "*********** $policy ***********" >> $outputfile
		echo "*********** $policy ***********"
		for condition in `ls $result_dir/$policy`
		do
			sudo rm -f $result_dir/$policy/$condition/mallocRand
			sudo rm -f $result_dir/$policy/$condition/run_test.sh
			sudo rm -f $result_dir/$policy/$condition/swap
			sudo rm -f $result_dir/$policy/$condition/timer.sh
			total=0
			finished=0
			entry_i=0
			cat $result_dir/$policy/$condition/result_exp_001.txt > a.out
			while read line
			do
				if [[ "$line" =~ "$finish_mark" ]]
				then
					finished=$(( finished + 1 ))
				elif [[ "$line" =~ "$entry_mark" ]]
				then
					entry_i=$(( entry_i + 1 ))
					#num_str=$(echo "$line"|grep -o "[0-9]*[0-9]")
					num_str=${line##*:}
					total=`echo "$total + $num_str" | bc`
					#total=$(( total + num_str ))
				fi
			done < a.out
				
			if [ "$finished" -ne 1 ]
			then
				echo "$result_dir/$policy/$condition/result_exp_001.txt not finished!!!" >> $outputfile
				echo "$result_dir/$policy/$condition/result_exp_001.txt not finished!!!"
			fi

			#oom=`expr $entry_num - $entry_i`
			#echo "$policy-$condition   $total    oom: $oom" >> $outputfile	
			#echo "$policy-$condition   $total    oom: $oom" 	
			echo "$policy-$condition,$total" >> $outputfile	
			echo "$policy-$condition,$total" 	
				
		done
	fi
done
