#!/bin/sh
for j in $(seq 10)
do
    for i in $(seq 10)
    do
        /mnt/mallocRand 920 &
        sleep 2
        kill -s INT $(pgrep mallocRand)
    done
    for i in $(seq 10)
    do
        /mnt/mallocRand 92000 &
        sleep 2
        kill -s INT $(pgrep mallocRand)
    done
done
echo "test2_p2, all mallocRand finished"
