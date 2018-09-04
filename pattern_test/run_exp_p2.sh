#!/bin/sh

workload=1

if [ $# != 1 ]
then
	echo "mallocRand parameter num:" $#
	echo "[WARN] mallocRand workload not specified. Using default: 1"
else
	workload=$1
fi

for i in $(seq 50) 
do
    /mnt/mallocRand $workload &
    sleep 2
    kill -s INT $(pgrep mallocRand)
    /mnt/mallocRand 920 &
    sleep 2
    kill -s INT $(pgrep mallocRand)
done
echo "run_exp_p2, all mallocRand finished"
