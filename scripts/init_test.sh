############################
# Initialization
# ensure ~/mnt is not mounted before going go

time=$(date + '%m%d-%H%M')

EXP_G=1
SUP_G=0
hostfree=0
pattern=steady
logfile=/home/yelly/balloon_policy_opt/log/testopt_default/default/log_$time.txt
outdir=/home/yelly/balloon_policy_opt/out/testopt_default/default/$time

if [ $# != 6 ]
then 
	echo "[WARN] Usage: init_test.sh <EXP_G> <SUP_G> <hostfree> <pattern> <logfile> <outdir>"
else
	EXP_G=$1
	SUP_G=$2
	hostfree=$3
	pattern=$4
	logfile=$5
	outdir=$6
fi

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
sudo sh /home/yelly/balloon_policy_opt/scripts/init_disks.sh exp $EXP_G $pattern
sudo sh /home/yelly/balloon_policy_opt/scripts/init_disks.sh sup $SUP_G $pattern

###################################
# log/results
sudo rm -f $logfile

###################################
# mom setup
sed -i "1c "$hostfree".0" /home/yelly/balloon_policy_opt/balloon_system/rules_command/host_free.txt
sed -i "74c log: $logfile" /home/yelly/balloon_policy_opt/balloon_system/mom-balloon.conf
#sed -i "74c log: stdio" /home/yelly/balloon_policy_opt/balloon_system/mom-balloon.conf

####################################
# removing existing outdir
sudo rm -rf $outdir
mkdir $outdir

