#!/bin/sh

workload=1

if [ $# != 1 ]
then
    echo "[WARN] mallocRand workload not specified. Using default: 1"
else
    workload=$1
fi

for i in $(seq 100) 
do
    /mnt/mallocRand $workload &
    sleep 2
    kill -s INT $(pgrep mallocRand)
done
echo "run_sup_steady, all mallocRand finished"
