#!/bin/bash

result_dir=/home/yelly/balloon_policy_opt/out/testopt
log_dir=/home/yelly/balloon_policy_opt/log/testopt

policy=ref.9
condition=host150000000_load200000_rep1

outputfile="/home/yelly/balloon_policy_opt/analysis/analysis_time_result_"$policy"_"$condition".csv"
# delete existing output file
sudo rm -f $outputfile

entry_mark=Done

cat $result_dir/$policy/$condition/result_exp_001.txt > a.out
while read line
do
	if [[ "$line" =~ "$entry_mark" ]]
	then
		time_str=${line%%D*}
		work_str=${line##*:}
		echo "$time_str,$work_str" >> $outputfile	
		echo "$time_str,$work_str" 	
	fi
done < a.out
				
echo "##################################" >> $outputfile	

entry_mark=balloon_cur:

cat $log_dir/$policy/log_$condition.txt > a.out
while read line
do
	if [[ "$line" =~ "$entry_mark" ]]
	then
		time_str=${line%%,*}
		mem_str=${line##*:}
		echo "$time_str,$mem_str" >> $outputfile	
		echo "$time_str,$mem_str" 	
	fi
done < a.out
