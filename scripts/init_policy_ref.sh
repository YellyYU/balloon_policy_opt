############################
# Initialization
# ensure ~/mnt is not mounted before going go

grow_ref=0.7
shrink_ref=0.3
interval_dir=testopt_default

if [ $# != 3 ]
then 
	echo "[WARN] Usage: init_policy_ref.sh <grow_ref> <shrink_ref> <interval_dir>"
else
	grow_ref=$1
	shrink_ref=$2
	interval_dir=$3
fi

wd=/home/yelly/balloon_policy_opt
policydir="adpref_gref"$grow_ref"_sref"$shrink_ref
log_policy_dir=$wd/log/$interval_dir/$policydir
out_policy_dir=$wd/out/$interval_dir/$policydir
#sudo rm -rf $log_policy_dir
#sudo rm -rf $out_policy_dir
mkdir $log_policy_dir
mkdir $out_policy_dir

###################################
# mom setup
rule_file=$wd/balloon_system/rules/testopt_adp_refp.rules
sed -i "6c (defvar grow_threshold $grow_ref)" $rule_file
sed -i "10c (defvar shrink_threshold $shrink_ref)" $rule_file
sed -i "14c (defvar grow_ref $grow_ref)" $rule_file
sed -i "18c (defvar shrink_ref $shrink_ref)" $rule_file
################ below is for opt_ref.rules
parameter_file=$wd/balloon_system/rules_command/parameters.txt
sed -i "1c ref" $parameter_file
sed -i "6,9c ref_grow_threshold: $grow_ref\nref_shrink_threshold: $shrink_ref\nref_grow_ref: $grow_ref\nref_shrink_ref: $shrink_ref" $parameter_file
