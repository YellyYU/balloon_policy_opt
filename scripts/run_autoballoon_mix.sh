#!/bin/bash

EXP_G=1
SUP_G=0
starttime=000000

if [ $# != 3 ]
then
    echo "[WARN] Usage: run_autoballoon.sh <EXP_G> <SUP_G> <starttime>"
else
    EXP_G=$1
    SUP_G=$2
    starttime=$3
fi

###############################
# beginning test

i=1
while [ "$i" -le "$EXP_G" ]; do
    name=$(printf "exp_%03d" $i)
    echo $name
    assign_port=$((i-1+4444))
    # the last parameter is used to compat with former script 
    # which take only one input workload as mallocRand argument
    # this argument is passed to run_exp_../run_sup_.. shell script of guests
    # but not used
    /home/yelly/balloon_policy_opt/scripts/run.sh $name $assign_port $starttime 50000
    sleep 1
    /home/yelly/qemu-2.8.0/scripts/qmp/qmp-dd-shell balloon localhost:$assign_port  94371840
    i=$(( i + 1 ))
done

i=1
while [ "$i" -le "$SUP_G" ]; do
    name=$(printf "sup_%03d" $i)
    echo $name
    assign_port=$((i-1+4444+$EXP_G))
    # the last parameter is used to compat with former script 
    # which take only one input workload as mallocRand argument
    # this argument is passed to run_exp_../run_sup_.. shell script of guests
    # but not used
    /home/yelly/balloon_policy_opt/scripts/run.sh $name $assign_port $starttime 50000
    sleep 1
    /home/yelly/qemu-2.8.0/scripts/qmp/qmp-dd-shell balloon localhost:$assign_port 94371840
    i=$(( i + 1 ))
done
echo boot vm finished
