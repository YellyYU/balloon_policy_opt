#!/bin/sh

maxworkload=50000
maxworkloadstep=25000
maxmaxworkload=150000
minmaxworkload=50000


for k in $(seq 2)
do
    while [ "$maxworkload" -le "$maxmaxworkload" ]
    do
        workloadstep=$(( maxworkload / 20 ))
        workload=0

        for j in $(seq 2)
        do
            for i in $(seq 20)
            do
                workload=$(( workload + workloadstep ))
                /mnt/mallocRand $workload &
                sleep 2
                kill -s INT $(pgrep mallocRand)
            done
            for i in $(seq 20)
            do
                /mnt/mallocRand $workload &
                sleep 2
                kill -s INT $(pgrep mallocRand)
                workload=$(( workload -  workloadstep ))
            done
        done
        for i in $(seq 20)
        do
            workload=$(( workload + workloadstep ))
            /mnt/mallocRand $workload &
            sleep 2
            kill -s INT $(pgrep mallocRand)
        done
        maxworkload=$(( maxworkload + maxworkloadstep ))
    done
    maxworkload=50000
done
echo "run_exp_mix_workload_slop_p40, all mallocRand finished"
