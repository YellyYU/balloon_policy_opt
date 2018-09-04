#!/bin/sh

while true; do
    time=`date "+%Y-%m-%d %H:%M:%S"`
    committed_as=`cat /proc/meminfo | grep "Committed_AS"`
   # committed_as=`cat /proc/meminfo | grep "Committed_AS"`
    echo $time, $committed_as
    sleep 2 
done
