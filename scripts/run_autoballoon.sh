#!/bin/bash

EXP_G=1
SUP_G=0
starttime=000000
workload=50000
exp_begin=94371840
sup_begin=94371840

if [ $# != 6 ]
then
    echo "[WARN] Usage: run_autoballoon.sh <EXP_G> <SUP_G> <starttime> <workload> <exp_begin> <sup_begin>"
else
    EXP_G=$1
    SUP_G=$2
    starttime=$3
    workload=$4
    exp_begin=$5
    sup_begin=$6
fi

###############################
# beginning test

i=1
while [ "$i" -le "$EXP_G" ]; do
    name=$(printf "exp_%03d" $i)
    echo $name
    assign_port=$((i-1+4444))
    /home/yelly/balloon_policy_opt/scripts/run.sh $name $assign_port $starttime $workload
    sleep 1
    /home/yelly/qemu-2.8.0/scripts/qmp/qmp-dd-shell balloon localhost:$assign_port $exp_begin 
    i=$(( i + 1 ))
done

i=1
while [ "$i" -le "$SUP_G" ]; do
    name=$(printf "sup_%03d" $i)
    echo $name
    assign_port=$((i-1+4444+$EXP_G))
    /home/yelly/balloon_policy_opt/scripts/run.sh $name $assign_port $starttime $workload
    sleep 1
    /home/yelly/qemu-2.8.0/scripts/qmp/qmp-dd-shell balloon localhost:$assign_port $sup_begin
    i=$(( i + 1 ))
done
echo boot vm finished
