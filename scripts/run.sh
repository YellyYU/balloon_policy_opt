#!/bin/bash
#qemu-system-x86_64 -kernel obj/linux-x86-defconfig/arch/x86_64/boot/bzImage -initrd obj/initramfs-busybox-x86.cpio.gz -hda ./alpine.qcow  -m 256M -nographic -append "console=ttyS0" -balloon virtio -qmp tcp:localhost:4444,server,nowait -enable-kvm
#qemu-system-x86_64 -kernel obj/linux-x86-defconfig/arch/x86_64/boot/bzImage -initrd obj/initramfs-busybox-x86.cpio.gz -hda ./alpine.qcow  -m 256M -append "console=ttyS0" -balloon virtio -qmp tcp:localhost:4444,server,nowait -enable-kvm -daemonize
#qemu-system-x86_64 -kernel ./x86-defconfig_bzImage -initrd initramfs.cpio.gz -hda ./test_2.qcow -m 90M -nographic -append "console=ttyS0 result_2" -balloon virtio -qmp tcp:localhost:4444,server,nowait -enable-kvm

## scirpts to run test1
#taskset -c 3,4,5,6,7,8 qemu-system-x86_64 -kernel ./x86-defconfig_bzImage -initrd initramfs-busybox-x86.cpio.gz -hda ./test_$1.qcow -m 256M -append "console=ttyS0 result=$1 time=$4 test=$2" -balloon virtio -qmp tcp:localhost:$3,server,nowait -enable-kvm -nographic > /dev/null 2>&1 &


## scirpts to run test2

if [ $# != 4 ]; then 
	echo "usage: $0 <name> <assign_port> <starttime> <workload>"
	exit
fi

tinyD=/home/yelly/tinyD

taskset -c 3,4,5,6,7,8 qemu-system-x86_64 -kernel $tinyD/image_env/bzImage -initrd $tinyD/image_env/initramfs-busybox-x86.cpio.gz -hda $tinyD/disks/disk_$1.img -m 256M -append "console=ttyS0 result=$1 time=$3 workload=$4" -balloon virtio -qmp tcp:localhost:$2,server,nowait -enable-kvm -nographic > /dev/null 2>&1 &

#taskset -c 3,4,5,6,7,8 qemu-system-x86_64 -kernel $tinyD/image_env/bzImage -initrd $tinyD/image_env/initramfs-busybox-x86.cpio.gz -hda $tinyD/disks/disk_$1.img -m 256M -append "console=ttyS0 result=$1 time=$3 workload=$4" -balloon virtio -qmp tcp:localhost:$2,server,nowait -enable-kvm -nographic
