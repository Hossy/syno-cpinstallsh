#!/opt/bin/bash

#statuslog=/opt/`/opt/bin/basename "$0" .sh`.laststatus
#$* > $statuslog
#whoami >> $statuslog
#env|sort >> $statuslog
#stty -a >> $statuslog
#/bin/ps ww| grep 17399 >> $statuslog
#/bin/ps ww| grep 'app=CrashPlanService' | grep -v grep | awk '{ print $1 }' >> $statuslog
#/opt/etc/init.d/S99crashplan status >> $statuslog

#cp /dev/null /opt/CrashPlanHealthCheck.shutdown

log=/opt/`/opt/bin/basename "$0" .sh`.log

function teeLog {
	msg="[`date`] $1"
	echo $msg
	echo $msg >> $log
}

#uptime=`dmesg | tail -n 1 | awk -F '.' '{ print gensub("\\\[", "", "g", $1) }'`
uptime=$(</proc/uptime)
uptime=${uptime%%.*}
if [ $uptime -le 600 ]; then
	teeLog "Uptime is $uptime.  Skipping run."
	[ -f "/opt/CrashPlanHealthCheck.shutdown-ack" ] || cp /dev/null /opt/CrashPlanHealthCheck.shutdown-ack
	exit 1
fi

#Cleanup shutdown flag
if [ -f "/opt/CrashPlanHealthCheck.shutdown-ack" ]; then
	rm /opt/CrashPlanHealthCheck.shutdown-ack
	rm /opt/CrashPlanHealthCheck.shutdown
fi

#Don't run -- shutdown flag
if [ -f "/opt/CrashPlanHealthCheck.shutdown" ]; then
    teeLog "Shutdown flag set.  Skipping run."
    exit 2
fi

if [ "`/opt/etc/init.d/S99crashplan status`" = "CrashPlan Engine is stopped." ]; then
	teeLog "whoami: `whoami`"
	#/opt/bin/screen -list | egrep '^\s\S' | awk '{print $1}'
	teeLog "Exiting existing CrashPlan screens:"
	for s in `/opt/bin/screen -list | grep 'CrashPlan' | awk '{print $1}'`; do
		teeLog $s
		/opt/bin/screen -S $s -X quit
	done
	
	teeLog "Starting CrashPlan [SHELL=$SHELL]"
	/opt/bin/screen -dmS CrashPlan $SHELL -c '/opt/etc/init.d/S99crashplan start; $SHELL'
fi
