#!/bin/sh

workload=50000
workloadstep=25000
maxworkload=150000
minworkload=50000

workload_75=75000
workload_100=100000
workload_125=125000

parameter_file=parameters.txt

sed -i "1,4c step_grow_threshold: 0.7\nstep_shrink_threshold: 0.4\nstep_grow_step: 46000000\nstep_shrink_step: 46000000" $parameter_file 
