#!/bin/sh

workload=50000
workloadstep=25000
maxworkload=125000
minworkload=50000

workload_50=50000
workload_75=75000
workload_100=100000
workload_125=125000

parameter_file=/home/yelly/balloon_policy_opt/balloon_system/rules_command/parameters.txt

for k in $(seq 2)
do
    while [ "$workload" -le "$maxworkload" ]
    do
        echo  "$(date +'%m%d-%H%M%S') workload: $workload"
        #if [ "$workload" -le "$workload_50" ]; then
            #echo  "workload <= 50000"
            # there's consistency problem, but I don't think it's a big issue...
            #sed -i "1,4c step_grow_threshold: 0.9\nstep_shrink_threshold: 0.3\nstep_grow_step: 26000000\nstep_shrink_step: 26000000" $parameter_file 
        #elif [ "$workload" -le "$workload_100" ]; then
        if [ "$workload" -le "$workload_50" ]; then
            echo  "workload <= 50000"
            sed -i "1c ref" $parameter_file 
            sed -i "6,9c ref_grow_threshold: 0.6\nref_shrink_threshold: 0.4\nref_grow_ref: 0.6\nref_shrink_ref: 0.4" $parameter_file 
#            sed -i "3c step_grow_step: 46000000" $parameter_file &
#            sed -i "4c step_shrink_step: 46000000" $parameter_file &
#            sed -i "1c step_grow_threshold: 0.7" $parameter_file &
#            sed -i "2c step_shrink_threshold: 0.3" $parameter_file &
        elif [ "$workload" -le "$workload_75" ]; then
            echo  "workload > 50000, <= 75000"
            sed -i "1c ref" $parameter_file 
            sed -i "6,9c ref_grow_threshold: 0.9\nref_shrink_threshold: 0.3\nref_grow_ref: 0.9\nref_shrink_ref: 0.3" $parameter_file 
        elif [ "$workload" -le "$workload_100" ]; then
            echo  "workload > 75000, <= 100000"
            sed -i "1,5c step\nstep_grow_threshold: 0.7\nstep_shrink_threshold: 0.6\nstep_grow_step: 100663296\nstep_shrink_step: 100663296" $parameter_file 
        else
            echo  "workload > 100000"
            sed -i "1,5c step\nstep_grow_threshold: 0.8\nstep_shrink_threshold: 0.6\nstep_grow_step: 100663296\nstep_shrink_step: 100663296" $parameter_file 
            #sed -i "1,5c step\nstep_grow_threshold: 0.6\nstep_shrink_threshold: 0.6\nstep_grow_step: 67108864\nstep_shrink_step: 67108864" $parameter_file 
        fi

	sleep 210
#        for j in $(seq 5)
#        do
#            for i in $(seq 10)
#            do
#                sleep 2
#            done
#            for i in $(seq 10)
#            do
#                sleep 2
#            done
#        done
        workload=$(( workload + workloadstep ))
    done
    workload=50000
done
