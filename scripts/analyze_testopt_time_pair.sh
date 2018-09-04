#!/bin/bash

result_dir=/home/yelly/balloon_policy_opt/out/opt
log_dir=/home/yelly/balloon_policy_opt/log/opt

policy=opt
condition=mix_workload_slop_p100_125

outputfile="/home/yelly/balloon_policy_opt/analysis/analysis_pair_time_"$policy"_"$condition"125_"$(date '+%m%d-%H%M')".csv"
# delete existing output file
sudo rm -f $outputfile

entry_mark=Done

echo "#############exp results" >> $outputfile
echo "time,work" >> $outputfile
 
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
				
echo " ,time,memory" >> $outputfile

mem_mark="ddtest0 -- balloon_cur:"
swap_mark="ddtest0 -- swap_in:"

cat $log_dir/$policy/log_$condition.txt > a.out
while read line
do
	if [[ "$line" =~ "$mem_mark" ]]
	then
		time_str=${line%%,*}
		mem_str=${line##*:}
		echo "mem,$time_str,$mem_str" >> $outputfile	
		echo "mem,$time_str,$mem_str" 	
	fi
	
	if [[ "$line" =~ "$swap_mark" ]]
	then
		time_str=${line%%,*}
		swap_str=${line##*-}
		swap_in_str=${swap_str%%,*}
		swap_out_str=${swap_str##*,}
		swap_in_str=${swap_in_str##*:}
		swap_out_str=${swap_out_str##*:}
		echo "swap_in/out,$time_str,$swap_in_str,$swap_out_str"
		echo "swap_in/out,$time_str,$swap_in_str,$swap_out_str" >> $outputfile	
	fi
done < a.out

entry_mark=Done

echo "#############sup results" >> $outputfile
echo "time,work" >> $outputfile
 
cat $result_dir/$policy/$condition/result_sup_001.txt > a.out
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
				
echo " ,time,memory" >> $outputfile

mem_mark="ddtest1 -- balloon_cur:"
swap_mark="ddtest1 -- swap_in:"

cat $log_dir/$policy/log_$condition.txt > a.out
while read line
do
	if [[ "$line" =~ "$mem_mark" ]]
	then
		time_str=${line%%,*}
		mem_str=${line##*:}
		echo "mem,$time_str,$mem_str" >> $outputfile	
		echo "mem,$time_str,$mem_str" 	
	fi
	
	if [[ "$line" =~ "$swap_mark" ]]
	then
		time_str=${line%%,*}
		swap_str=${line##*-}
		swap_in_str=${swap_str%%,*}
		swap_out_str=${swap_str##*,}
		swap_in_str=${swap_in_str##*:}
		swap_out_str=${swap_out_str##*:}
		echo "swap_in/out,$time_str,$swap_in_str,$swap_out_str"	
		echo "swap_in/out,$time_str,$swap_in_str,$swap_out_str" >> $outputfile	
	fi
done < a.out
