#!/bin/sh

maxworkload=50000

if [ $# != 1 ]
then
	echo "mallocRand parameter num: " $#
	echo "[WARN] run_exp_slop_p100 mallocRand maxworkload not specified. Using default: 50000"
else
	maxworkload=$1
fi

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
    workload=$(( workload - workloadstep ))
done
echo "run_exp_slop_p100, all mallocRand finished"
