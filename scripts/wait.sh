
target=000000

if [ $# != 1 ]
then
    echo "[WARN] Usage: wait.sh <targettime>"
else
    target=$1
fi

while true; do
    curTime=$(date +%H%M%S)
    if [ "$curTime" -gt "$target" ];then
        break
    fi
    sleep 1
done
