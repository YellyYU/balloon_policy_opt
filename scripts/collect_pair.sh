

if [ $# != 3 ]
then 
	echo "[WARN] Usage: collect.sh <EXP_G> <SUP_G> <outdir>"
else
	EXP_G=$1
	SUP_G=$2
	outdir=$3
fi


sleep 5

i=1
while [ "$i" -le "$EXP_G" ]; do
    formatid=$(printf "%03d" $i)
    echo exp_$formatid
    sudo mount /home/yelly/tinyD/disks/disk_exp_$formatid.img /home/yelly/mnt
#    cp ~/mnt/result_exp_$formatid.txt $outdir
    cp ~/mnt/result_exp_$formatid.txt $outdir
    cp ~/mnt/termlog.txt $outdir/termlog_exp_$formatid.txt
    sudo umount /home/yelly/mnt
    i=$(( i + 1 ))
done

i=1
while [ "$i" -le "$SUP_G" ]; do
    formatid=$(printf "%03d" $i)
    echo sup_$formatid
    sudo mount /home/yelly/tinyD/disks/disk_sup_$formatid.img /home/yelly/mnt
#    cp ~/mnt/result_exp_$formatid.txt $outdir
    cp ~/mnt/result_sup_$formatid.txt $outdir
    cp ~/mnt/termlog.txt $outdir/termlog_sup_$formatid.txt
    sudo umount /home/yelly/mnt
    i=$(( i + 1 ))
done
