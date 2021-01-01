#!/bin/bash

echo ""
echo "Health report for: ${HOSTNAME}"
echo ""
date
echo "----------------------------------------------------------------------"
echo ""
echo "DISK"
echo "===="
df -H | grep "Mounted\|/$"
echo ""
echo "MEMORY"
echo "======"
#cat /proc/meminfo | grep MemTotal
#cat /proc/meminfo | grep MemFree
TOTAL=$((`cat /proc/meminfo | grep MemTotal | cut -d":" -f2 | xargs | cut -d" " -f1` / 1024))
FREE=$((`cat /proc/meminfo | grep MemFree | cut -d":" -f2 | xargs | cut -d" " -f1` / 1024))
USED=$(($TOTAL-$FREE))
PCT_RAW=`echo "scale=2; $FREE/$TOTAL" | bc -l`
PCT_FREE=`echo "scale=1; ${PCT_RAW}*100" | bc -l`
PCT_USED=`echo "scale=1; 100-(${PCT_RAW}*100)" | bc -l`

echo "Total Memory: ${TOTAL} MB"
#echo "Free Memory:  ${FREE} MB (${PCT_FREE} %)"
echo "Used Memory:  ${USED} MB (${PCT_USED} %)"
echo ""
echo "----------------------------------------------------------------------"
echo ""
