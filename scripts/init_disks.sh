#!/bin/sh
diskdir="/home/yelly/tinyD/disks"
mntdir="/home/yelly/mnt"

# all existing disk imgs should have been removed before executing this script

MAX=10
guesttype="sup"
mounted=1
mount_i=1
pattern=steady

if [ $# != 3 ]
then
	echo "Usage: init_disks.sh <type> <num> <pattern>"
	exit
else
	guesttype=$1
	MAX=$2
	pattern=$3
fi

i=1
while [ "$i" -le $MAX ]; do
	formatid=$(printf "%03d" $i)
	diskname="disk_"$guesttype"_"$formatid".img"
	qemu-img create -f raw $diskdir/$diskname 3G
	mkfs.ext3 $diskdir/$diskname
	sudo mount $diskdir/$diskname $mntdir
	sudo cp "/home/yelly/balloon_policy_opt/pattern_test/run_"$guesttype"_"$pattern".sh" $mntdir/run_test.sh
	sudo cp /home/yelly/balloon_policy_opt/pattern_test/mallocRand $mntdir
	sudo cp /home/yelly/balloon_policy_opt/scripts/timer.sh $mntdir
	sudo cp /home/yelly/balloon_policy_opt/scripts/print_stat.sh $mntdir
	sudo dd if=/dev/zero of=$mntdir/swap bs=1M count=200
	while [ "$mount_i" -le "$mounted" ]; do
		sudo umount $mntdir
		ret=$?
		echo $ret
		if [ $ret -eq 0 ]
		then
			continue
		else
			break
		fi
	done
	i=$(( i + 1 ))
done
