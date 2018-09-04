#!/bin/sh
for i in $(seq 300)
do
    /mnt/mallocRand 920 &
    sleep 2
    kill -s INT $(pgrep mallocRand)
done
for i in $(seq 300)
do
    /mnt/mallocRand 92000 &
    sleep 2
    kill -s INT $(pgrep mallocRand)
done
echo "test3_p2, all mallocRand finished"
