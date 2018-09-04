#!/bin/sh
startTime=$1
program=ls
#echo hello world

while true; do
    curTime=$(date +%H%M%S)
    if [ $curTime -gt $startTime ];then
        echo start
        #$program
        break
    fi
    sleep 1
done
