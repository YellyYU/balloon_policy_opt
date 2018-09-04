############################
# Initialization
# ensure ~/mnt is not mounted before going go

grow_threshold=0.7
shrink_threshold=0.3
grow_step=1000000
shrink_step=1000000
interval_dir=testopt_default

if [ $# != 5 ]
then 
	echo "[WARN] Usage: init_policy.sh <grow_threshold> <shrink_threshold> <grow_step> <shrink_step> <interval_dir>"
else
	grow_threshold=$1
	shrink_threshold=$2
	grow_step=$3
	shrink_step=$4
	interval_dir=$5
fi

wd=/home/yelly/balloon_policy_opt
policydir="adp_stp_gth"$grow_threshold"_sth"$shrink_threshold"_gst"$grow_step"_sst"$shrink_step
log_policy_dir=$wd/log/$interval_dir/$policydir
out_policy_dir=$wd/out/$interval_dir/$policydir
#sudo rm -rf $log_policy_dir
#sudo rm -rf $out_policy_dir
mkdir $log_policy_dir
mkdir $out_policy_dir

###################################
# mom setup
rule_file=$wd/balloon_system/rules/testopt_adp_step.rules
sed -i "6c (defvar grow_threshold $grow_threshold)" $rule_file
sed -i "10c (defvar shrink_threshold $shrink_threshold)" $rule_file
sed -i "15c (defvar grow_step $grow_step)" $rule_file
sed -i "20c (defvar shrink_step $shrink_step)" $rule_file
############ below is for opt_step.rules
parameter_file=$wd/balloon_system/rules_command/parameters.txt
sed -i "1,5c step\nstep_grow_threshold: $grow_threshold\nstep_shrink_threshold: $shrink_threshold\nstep_grow_step: $grow_step\nstep_shrink_step: $shrink_step" $parameter_file
