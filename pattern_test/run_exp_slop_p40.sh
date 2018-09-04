#!/bin/sh

maxworkload=50000

if [ $# != 1 ]
then
	echo "mallocRand parameter num: " $#
	echo "[WARN] test_exp_slop_p40 mallocRand maxworkload not specified. Using default: 50000"
else
	maxworkload=$1
fi

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
        workload=$(( workload - workloadstep ))
    done
done
for i in $(seq 20)
do
    workload=$(( workload + workloadstep ))
    /mnt/mallocRand $workload &
    sleep 2
    kill -s INT $(pgrep mallocRand)
done
echo "test_exp_slop_p40, all mallocRand finished"
