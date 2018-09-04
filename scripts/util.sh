#!/bin/bash

result_dir=/home/yelly/balloon_policy_opt/out/testopt
log_dir=/home/yelly/balloon_policy_opt/log/testopt

step=1000000	
stepstep=5000000
maxstep=46000000
while [ "$step" -le "$maxstep" ]; do
	sudo mv $log_dir"/gth0.7_sth0.3_gst"$step"_sst"$step $log_dir"/adpt_stp_gth0.7_sth0.3_gst"$step"_sst"$step
	sudo mv $out_dir"/gth0.7_sth0.3_gst"$step"_sst"$step $out_dir"/adpt_stp_gth0.7_sth0.3_gst"$step"_sst"$step

	step=$(( step + stepstep ))
done
