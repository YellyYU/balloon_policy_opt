#!/bin/sh
for i in $(seq 10)
do
    /mnt/mallocRand 920 &
    sleep 2
    kill -s INT $(pgrep mallocRand)
    /mnt/mallocRand 92000 &
    sleep 2
    kill -s INT $(pgrep mallocRand)
done
echo "test1_p2, all mallocRand finished"
