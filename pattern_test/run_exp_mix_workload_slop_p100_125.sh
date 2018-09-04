#!/bin/sh

maxworkload=50000
maxworkloadstep=25000
maxmaxworkload=125000
minmaxworkload=50000


for k in $(seq 2)
do
    while [ "$maxworkload" -le "$maxmaxworkload" ]
    do
        workloadstep=$(( maxworkload / 50 ))
        workload=0

        for i in $(seq 50)
        do
            workload=$(( workload + workloadstep ))
            /mnt/mallocRand $workload &
            sleep 2
            kill -s INT $(pgrep mallocRand)
        done
        for i in $(seq 50)
        do
            /mnt/mallocRand $workload &
            sleep 2
            kill -s INT $(pgrep mallocRand)
            workload=$(( workload -  workloadstep ))
        done
        maxworkload=$(( maxworkload + maxworkloadstep ))
    done
    maxworkload=50000
done
echo "run_exp_mix_workload_slop_p100, all mallocRand finished"
