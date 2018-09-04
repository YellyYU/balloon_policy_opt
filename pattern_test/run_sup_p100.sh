#!/bin/sh

workload=1

if [ $# != 1 ]
then
	echo "mallocRand parameter num: " $#
	echo "[WARN] run_sup_p100 mallocRand not specified. Using default: 1"
else
	workload=$1
fi

for i in $(seq 50)
do
    /mnt/mallocRand 920 &
    sleep 2
    kill -s INT $(pgrep mallocRand)
done
for i in $(seq 50)
do
    /mnt/mallocRand $workload &
    sleep 2
    kill -s INT $(pgrep mallocRand)
done
echo "run_sup_p100, all mallocRand finished"
