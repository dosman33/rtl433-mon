#!/bin/bash
# 2019-03-10 / dosman / kill running rtl_433 and restart with new log file
# https://github.com/dosman33/rtl433-mon
# 
# Call from cron like this, restarts rtl433 daily just after midnight cutting to a new output log:
#0 0 * * * /home/pi/bin/rtl433-restart.sh

###############################################################################
RTL=/usr/local/bin/rtl_433
DATE=`date +%Y%m%d`
OUTPATH=/var/www/html/rtl433/csv
LOG=${OUTPATH}/${DATE}_rtl.log

###############################################################################

PID=`ps -ef | grep $RTL | grep -v grep | awk '{print $2}'`
if [[ -n $PID ]];then
	kill $PID
	sleep 5
fi

$RTL -G -f 433920000 -f 315000000 -H 2 -F csv:${LOG} > /dev/null 2>&1 &

