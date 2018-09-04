

if [ $# != 2 ]
then 
	echo "[WARN] Usage: collect.sh <EXP_G> <outdir>"
else
	EXP_G=$1
	outdir=$2
fi


sleep 5

i=1
while [ "$i" -le "$EXP_G" ]; do
    formatid=$(printf "%03d" $i)
    echo exp_$formatid
    sudo mount /home/yelly/tinyD/disks/disk_exp_$formatid.img /home/yelly/mnt
#    cp ~/mnt/result_exp_$formatid.txt $outdir
    cp ~/mnt/* $outdir
    sudo umount /home/yelly/mnt
    i=$(( i + 1 ))
done
