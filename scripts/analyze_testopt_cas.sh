#!/bin/bash

result_dir=/home/yelly/balloon_policy_opt/out/testopt_collect2_policy3
#log_dir=/home/yelly/balloon_policy_opt/log/testopt_collect2_policy3

policy=adp_stp_gth.8_sth.6_gst33554432_sst33554432
condition=begin136314880104857600_host0_load100000_slop_p40

outputfile="/home/yelly/balloon_policy_opt/analysis/analysis_cas_workload100_slop_p40_"$(date '+%m%d-%H%M')".csv"
# delete existing output file
sudo rm -f $outputfile

begin_mark=begin
entry_mark=Committed_AS

cat $result_dir/$policy/$condition/termlog_exp_001.txt > a.out
while read line
do
	if [[ "$line" =~ "$begin_mark" ]]
	then
		while read line
		do
			if [[ "$line" =~ "$entry_mark" ]]
			then
				time_str=${line%%,*}
				cas_str=${line##*:}
				cas_str=${cas_str%%k*}
				echo "$time_str,$cas_str" >> $outputfile	
				echo "$time_str,$cas_str" 	
			fi
		done
	fi
done < a.out
