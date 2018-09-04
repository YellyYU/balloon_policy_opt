############################
# Initialization
# ensure ~/mnt is not mounted before going go

EXP_G=1
SUP_G=0
hostfree=0
testname=testname
ref=0.7

if [ $# != 5 ]
then 
	echo "[WARN] Usage: disk_init.sh <EXP_G> <SUP_G> <hostfree> <testname> <ref>"
else
	EXP_G=$1
	SUP_G=$2
	hostfree=$3
	testname=$4
	ref=$5
fi

policydir=ref$ref
logfile="/home/yelly/balloon_policy_opt/log/testopt/"$policydir"/log_"$testname".txt"
outdir="/home/yelly/balloon_policy_opt/out/testopt/"$policydir"/"$testname

################################
# disks
i=1
mounted=1
while [ "$i" -le "$mounted" ]; do
	sudo umount ~/mnt
	ret=$?
	echo $ret
	if [ $ret -eq 0 ]
	then
		continue
	else
		break
	fi
done

sudo rm -rf /home/yelly/tinyD/disks/*
sudo sh /home/yelly/balloon_policy_opt/scripts/init_disks.sh exp $EXP_G
sudo sh /home/yelly/balloon_policy_opt/scripts/init_disks.sh sup $SUP_G

###################################
# log/results
sudo rm -f $logfile

###################################
# mom setup
sed -i "1c "$hostfree".0" /home/yelly/balloon_policy_opt/balloon_system/rules_command/host_free.txt
sed -i "74c log: $logfile" /home/yelly/balloon_policy_opt/balloon_system/mom-balloon.conf
sed -i "6c (defvar grow_threshold $ref)" /home/yelly/balloon_policy_opt/balloon_system/rules/testopt_refp.rules
sed -i "14c (defvar grow_ref $ref)" /home/yelly/balloon_policy_opt/balloon_system/rules/testopt_refp.rules
#sed -i "74c log: stdio" /home/yelly/balloon_policy_opt/balloon_system/mom-balloon.conf

####################################
# removing existing outdir
sudo rm -rf $outdir
mkdir $outdir

