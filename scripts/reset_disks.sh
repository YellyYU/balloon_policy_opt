#!/bin/sh
diskdir="/home/yelly/tinyD/disks"
mntdir="/home/yelly/mnt"

MAX=10

if [ $# != 1 ]
then
	echo "warning: MAX disk not specified, reset default number:$MAX"
else
	MAX=$1
fi

i=1
while [ "$i" -le $MAX ]; do
	sudo mount $diskdir/disk$i.img $mntdir
	sudo rm -rf $mntdir/*
	sudo cp -a /home/yelly/balloon_policy_opt/pattern_test/. $mntdir
	sudo cp /home/yelly/balloon_policy_opt/scripts/timer.sh $mntdir
	sudo dd if=/dev/zero of=$mntdir/swap bs=1M count=200
	sudo umount $mntdir
	i=$(( i + 1 ))
done
