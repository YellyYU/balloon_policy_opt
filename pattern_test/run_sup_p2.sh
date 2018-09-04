#!/bin/sh

workload=1

if [ $# != 1]
then
	echo "mallocRand parater num: " $#
	echo "[WARN] test_sup_p2 mallocRand workload not specified. Using default: 1"
else
	workload=$1
fi

for i in $(seq 50)
do
    /mnt/mallocRand 920 &
    sleep 2
    kill -s INT $(pgrep mallocRand)
    /mnt/mallocRand $workload &
    sleep 2
    kill -s INT $(pgrep mallocRand)
done
echo "test_sup_p2 , all mallocRand finished"
