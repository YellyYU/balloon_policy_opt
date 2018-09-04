#!/bin/sh

workload=50000
workloadstep=25000
maxworkload=125000
minworkload=50000

for k in $(seq 2)
do
    while [ "$workload" -le "$maxworkload" ]
    do
        for j in $(seq 5)
        do
            for i in $(seq 10)
            do
                /mnt/mallocRand $workload &
                sleep 2
                kill -s INT $(pgrep mallocRand)
            done
            for i in $(seq 10)
            do
                /mnt/mallocRand 920 &
                sleep 2
                kill -s INT $(pgrep mallocRand)
            done
        done
        workload=$(( workload + workloadstep ))
    done
    workload=50000
done
echo "test_exp_mix_workload_p20, all mallocRand finished"
