#!/bin/sh

maxworkload=50000

if [ $# != 1 ]
then
	echo "mallocRand parameter num: " $#
	echo "[WARN] test_sup_slop_p40 mallocRand maxworkload not specified. Using default: 50000"
else
	maxworkload=$1
fi

workloadstep=$(( maxworkload / 20 ))
workload=$maxworkload

for j in $(seq 2)
do
    for i in $(seq 20)
    do
        /mnt/mallocRand $workload &
        sleep 2
        kill -s INT $(pgrep mallocRand)
        workload=$(( workload - workloadstep ))
    done
    for i in $(seq 20)
    do
        workload=$(( workload + workloadstep ))
        /mnt/mallocRand $workload &
        sleep 2
        kill -s INT $(pgrep mallocRand)
    done
done
for i in $(seq 20)
do
    /mnt/mallocRand $workload &
    sleep 2
    kill -s INT $(pgrep mallocRand)
    workload=$(( workload - workloadstep ))
done
echo "test_sup_slop_p40, all mallocRand finished"
