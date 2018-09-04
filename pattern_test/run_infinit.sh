#!/bin/sh
while :
do
    /mnt/mallocRand 92000 &
    sleep 2
    kill -s INT $(pgrep mallocRand)
    /mnt/mallocRand 920 &
    sleep 2
    kill -s INT $(pgrep mallocRand)
done

