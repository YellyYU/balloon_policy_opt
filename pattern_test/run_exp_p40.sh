#!/bin/sh

workload=50000

if [ $# != 1 ]
then
	echo "mallocRand parameter num: " $#
	echo "[WARN] test_exp_p40 mallocRand workload not specified. Using default: 500000"
else
	workload=$1
fi

for j in $(seq 2)
do
    for i in $(seq 20)
    do
        /mnt/mallocRand $workload &
        sleep 2
        kill -s INT $(pgrep mallocRand)
    done
    for i in $(seq 20)
    do
        /mnt/mallocRand 920 &
        sleep 2
        kill -s INT $(pgrep mallocRand)
    done
done
for i in $(seq 20)
do
    /mnt/mallocRand $workload &
    sleep 2
    kill -s INT $(pgrep mallocRand)
done
echo "test_exp_p40, all mallocRand finished"
