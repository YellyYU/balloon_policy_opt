#!/bin/sh

maxworkload=50000
maxworkloadstep=25000
maxmaxworkload=150000
minmaxworkload=50000


for k in $(seq 2)
do
    while [ "$maxworkload" -le "$maxmaxworkload" ]
    do
        workloadstep=$(( maxworkload / 10 ))
        workload=$maxworkload

        for j in $(seq 5)
        do
            for i in $(seq 10)
            do
                /mnt/mallocRand $workload &
                sleep 2
                kill -s INT $(pgrep mallocRand)
                workload=$(( workload -  workloadstep ))
            done
            for i in $(seq 10)
            do
                workload=$(( workload + workloadstep ))
                /mnt/mallocRand $workload &
                sleep 2
                kill -s INT $(pgrep mallocRand)
            done
        done
        maxworkload=$(( maxworkload + maxworkloadstep ))
    done
    maxworkload=50000
done
echo "run_sup_mix_workload_slop_p20, all mallocRand finished"
