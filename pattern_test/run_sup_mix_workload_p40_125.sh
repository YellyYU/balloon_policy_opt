#!/bin/sh

workload=50000
workloadstep=25000
maxworkload=125000
minworkload=50000

for k in $(seq 2)
do
    while [ "$workload" -le "$maxworkload" ]
    do
        for j in $(seq 2)
        do
            for i in $(seq 20)
            do
                /mnt/mallocRand 920 &
                sleep 2
                kill -s INT $(pgrep mallocRand)
            done
            for i in $(seq 20)
            do
                /mnt/mallocRand $workload &
                sleep 2
                kill -s INT $(pgrep mallocRand)
            done
        done
        for i in $(seq 20)
        do
            /mnt/mallocRand 920 &
            sleep 2
            kill -s INT $(pgrep mallocRand)
        done
        workload=$(( workload + workloadstep ))
    done
    workload=50000
done
echo "test_sup_mix_workload_p40, all mallocRand finished"
