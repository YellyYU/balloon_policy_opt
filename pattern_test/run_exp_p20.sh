#!/bin/sh

workload=1

if [ $# != 1 ]
then
	echo "mallocRand parameter num: " $#
	echo "[WARN] test_exp_p20 mallocRand workload not specified. Using default: 1"
else
	workload=$1
fi

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
echo "test_exp_p20, all mallocRand finished"
