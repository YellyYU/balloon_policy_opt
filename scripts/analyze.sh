#!/bin/bash

result_dir=/home/yelly/balloon_policy_opt/out
entry_num_map=(20 200 600)

test_num=2
file_num=10

test_i=2
finish_mark=finished
entry_mark=Done
while [ "$test_i" -le "$test_num" ]; do
	outputfile=$result_dir/analysis_$test_i.txt

	# delete existing output file
	rm -f $outputfile
	
	echo "test$test_i" >> $outputfile
	echo "test$test_i"
	for policy in `ls $result_dir/test$test_i`
	do	
		if [ -d $result_dir/test$test_i/$policy ]
		then
			#echo "policy: $policy"
			#echo "analyzing testfiles in dir: $result_dir/test$test_i/$policy"
			total=0
			oom=0
			file_i=0
			for testfile in `ls $result_dir/test$test_i/$policy`
			do
			#	echo "testfile: $testfile"
				file_i=$(( file_i + 1))
				finished=0
				entry_i=0
				cat $result_dir/test$test_i/$policy/$testfile > a.out
				while read line
				do
					if [[ "$line" =~ "$finish_mark" ]]
					then
						finished=$(( finished + 1 ))
						#echo "[OK]test$test_i/$policy/$testfile finished, finished value: $finished"
					elif [[ "$line" =~ "$entry_mark" ]]
					then
						entry_i=$(( entry_i + 1 ))
						num_str=$(echo "$line"|grep -o "[0-9]*[0-9]")
#						echo "expr $total + $num_str"
						total=`expr $total + $num_str`
					else
						echo "unexpected output: $line" >> $outputfile
					fi
				done < a.out
				#echo "finished at end of file: $finished"
				if [ "$finished" -ne 1 ]
				then
					echo "test$test_i/$policy/$testfile not finished!!!" >> $outputfile
					echo "test$test_i/$policy/$testfile not finished!!!"
				fi
				oom_this=`expr ${entry_num_map[$(( test_i - 1 ))]} - $entry_i`
				oom=`expr $oom_this + $oom`
			done
			if [ "$file_i" -ne "$file_num" ]
			then
				echo "test$test_i/$policy does not have enough test files!!!" >> $outputfile	
				echo "test$test_i/$policy does not have enough test files!!!"	
			else
				echo "$policy\t$total\t$oom" >> $outputfile	
				echo "$policy\t$total\t$oom" 	
			fi	
		fi
	done
	test_i=$(( test_i + 1 ))
done
