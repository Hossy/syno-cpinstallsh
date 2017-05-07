#!/opt/bin/bash

#Java memory heap override
#Reference: http://support.code42.com/CrashPlan/Latest/Troubleshooting/CrashPlan_Runs_Out_Of_Memory_And_Crashes
#javaheap=4096
max_user_watches=1048576

###################################################################################
#########################   DO NOT EDIT BELOW THIS LINE   #########################
###################################################################################

### Constants
maxhealthchecks=12

### Validate javaheap variable
javaheapre='^[0-9]+$'
if [ -n "$javaheap" ] && ! [[ $javaheap =~ $javaheapre ]]; then
  echo "The value specified for javaheap, ${javaheap}, is not a number.  Please fix."
  exit 1
fi


### Validate arguments
if [ ! -n "$1" ]; then
  echo 'Please specify the CrashPlan tgz file.'
  exit 2
fi

if [ ! -r "$1" ]; then
  echo "I can't read that file."
  exit 2
fi


### Set path
if [[ "$PATH" != */opt/bin:/opt/sbin:/opt/crashplan/jre/bin* ]]; then
  export PATH=/opt/bin:/opt/sbin:/opt/crashplan/jre/bin:$PATH
fi


### Validate ipkg installation
VALID=1
REQDIPKGS='bash coreutils cpio screen sed wget-ssl'
for PKG in $REQDIPKGS; do
    if [ ! "$(ipkg list_installed | sed -ne '/^'$PKG'/ s/^\([^ ]*\) - .*/\1/p')" == "$PKG" ]; then
        echo "Missing ipkg package: $PKG"
        VALID=0
    fi
done
if [ "$VALID" == '0' ]; then
    exit 2
fi


### Verify CrashPlan is not running
if [ -f /opt/crashplan/lib/com.backup42.desktop.jar ] && [ -x /etc/init.d/crashplan ] && [ -f /opt/crashplan/install.vars ] && [ -x /etc/init.d/crashplan ] && [ -x /opt/crashplan/bin/CrashPlanEngine ]; then
  echo 'Previous CrashPlan installation detected.  Checking state.'
  if [ "$(/etc/init.d/crashplan status)" != "CrashPlan Engine is stopped." ] && [ "$?" -eq "0" ]; then
    echo 'CrashPlan is not stopped.  Attempting to stop...'
    /etc/init.d/crashplan stop
    echo 'Waiting 30s for CrashPlan to fully stop...'
    sleep 30
    if [ "$(/etc/init.d/crashplan status)" != "CrashPlan Engine is stopped." ] && [ "$?" -eq "0" ] && [ -n "$(/bin/ps ww| grep 'app=CrashPlanService' | grep -v grep)" ]; then
      echo 'CrashPlan did not stop.  Cannot install atop a running instance.  Please stop CrashPlan first.'
      exit 3
    fi
  fi
fi

#Double-check
if [ -n "$(/bin/ps ww| grep 'app=CrashPlanService' | grep -v grep)" ]; then
  echo 'CrashPlan still appears to be running.  Please stop it manually and try again.'
  exit 3
fi

## #Check max_user_watches (no changes will be made)
## #https://support.code42.com/CrashPlan/4/Troubleshooting/Linux_Real-Time_File_Watching_Errors
## if [ -r /proc/sys/fs/inotify/max_user_watches ]; then
##   cur_max_user_watches=`cat /proc/sys/fs/inotify/max_user_watches`
##   if [ "$cur_max_user_watches" != "$max_user_watches" ]; then
##     echo "max_user_watches is currently set to $cur_max_user_watches."
##     echo "You might consider increasing this to $max_user_watches"
##     echo 'See: https://support.code42.com/CrashPlan/4/Troubleshooting/Linux_Real-Time_File_Watching_Errors'
##     sleep 5
##   fi
## fi

#Check max_user_watches
#https://support.code42.com/CrashPlan/4/Troubleshooting/Linux_Real-Time_File_Watching_Errors
#See README.  Synology does it differently.
if [ -r /proc/sys/fs/inotify/max_user_watches ]; then
  cur_max_user_watches=`cat /proc/sys/fs/inotify/max_user_watches`
  if [[ "$cur_max_user_watches" =~ ^[0-9]+$ ]]; then
    if [ "$cur_max_user_watches" -lt "$max_user_watches" ]; then
      echo "Increasing max_user_watches from $cur_max_user_watches to $max_user_watches..."
      echo 'See: https://support.code42.com/CrashPlan/4/Troubleshooting/Linux_Real-Time_File_Watching_Errors'
      echo "$max_user_watches" > /proc/sys/fs/inotify/max_user_watches
      if [ -n "$(cat /etc.defaults/synoinfo.conf | grep 's2s_watches_max')" ]; then
        #s2s_watches_max is already defined. Edit it
        perl -pi.bak -e "s/^(s2s_watches_max=\"?)[0-9]+(\"?.*?)$/\${1}${max_user_watches}\${2}/" /etc.defaults/synoinfo.conf || exit 4
      else
        #Define s2s_watches_max
        cp /etc.defaults/synoinfo.conf{,.bak}
        (cat >> /etc.defaults/synoinfo.conf || exit 4) <<EOL

# for CrashPlan
s2s_watches_max="1048576"
EOL
      fi
    fi
  fi
fi

### Clean up from previous installation
if [ -d /opt/crashplan/upgrade ]; then
  echo "Removing previous version's upgrade files..."
  rm -r /opt/crashplan/upgrade
fi

if [ -d /opt/crashplan-install ]; then
  echo 'Removing old install files...'
  rm -r /opt/crashplan-install
fi

if [ -L /opt/etc/init.d/S99crashplan ]; then
  echo 'Removing Optware init.d symbolic link...'
  rm /opt/etc/init.d/S99crashplan
fi

if [ -L /usr/syno/etc/rc.d/S99crashplan ]; then
  echo 'Removing rc.d symbolic link...'
  rm /usr/syno/etc/rc.d/S99crashplan
fi

if [ -L /usr/syno/etc/rc.d/S99crashplan.sh ]; then
  echo 'Removing rc.d .sh symbolic link...'
  rm /usr/syno/etc/rc.d/S99crashplan.sh
fi

if [ -L /opt/bin/CrashPlanDesktop ]; then
  echo 'Removing CrashPlanDesktop symbolic link...'
  rm /opt/bin/CrashPlanDesktop
fi


### CrashPlan install
tar -xvf $1 -C /opt

if [ ! -x /opt/crashplan-install/install.sh ]; then
  echo 'Failed to extract CrashPlan install files.'
  exit 5
fi

if [ -f /opt/crashplan/install.vars ]; then
  echo 'Setting up for reinstall...'
  rm /opt/crashplan/install.vars || exit 5
fi

echo 'Editing CrashPlan install.sh...'
perl -pi -e 's/#!\/bin\/bash/#!\/opt\/bin\/bash/' /opt/crashplan-install/install.sh || exit 6
perl -pi -e 's/\$WGET_PATH \$JVMURL/\$WGET_PATH --no-check-certificate \$JVMURL/' /opt/crashplan-install/install.sh || exit 6
perl -pi -e 's/(^|["'\'']|\s+)sed /\1\/opt\/bin\/sed /' /opt/crashplan-install/install.sh || exit 6

echo 'Use these settings:'
echo ''
echo -e 'CrashPlan will install to: \e[1;36m/opt\e[0m/crashplan  *** Note: Beginning with CrashPlan 3.6.4, leave off "/crashplan" when entering the path.'
echo -e 'And put links to binaries in: \e[1;36m/opt/bin\e[0m'
echo 'And store datas in: /opt/crashplan/manifest'
echo 'Your init.d dir is: /etc/init.d'
#echo -e 'Your current runlevel directory is: \e[1;36m/usr/syno/etc/rc.d\e[0m'
echo -e 'Your current runlevel directory is: \e[1;36m/opt/etc/init.d\e[0m  *** Note: Requires Optware fix from http://forum.synology.com/enu/viewtopic.php?f=77&t=51025'
echo ''

cd /opt/crashplan-install
./install.sh

if [ "$?" -ne "0" ]; then
  echo 'CrashPlan installation failed.  Cannot continue.'
  exit 7
fi


### Edit CrashPlan files after install
echo 'Editing files...'

#Edit /etc/init.d/crashplan
#mv /usr/syno/etc/rc.d/S99crashplan /usr/syno/etc/rc.d/S99crashplan.sh || exit 8
perl -pi.bak -e 's/SCRIPTNAME=(?!env\\ PATH=\/opt\/bin:\/opt\/sbin:\${PATH}\\ )/SCRIPTNAME=env\\ PATH=\/opt\/bin:\/opt\/sbin:\${PATH}\\ /' /etc/init.d/crashplan || exit 8

#Edit /opt/crashplan/bin/CrashPlanEngine
perl -pi.bak -e 's/#!\/bin\/bash/#!\/opt\/bin\/bash/' /opt/crashplan/bin/CrashPlanEngine || exit 8
perl -pi -e "s/ps (?:-eo 'pid,cmd'|-p)( ?)/ps ww\1/" /opt/crashplan/bin/CrashPlanEngine || exit 8
perl -pi -e 's/(\s*)nice /\1\/opt\/bin\/nice /' /opt/crashplan/bin/CrashPlanEngine || exit 8

#Edit for open file count
sed -i 'N;N;/#############################################################\n/a\
# Increase open files limit\
ulimit -n 131072\
' /opt/crashplan/bin/CrashPlanEngine

#Edit java heap size
#Recheck $javaheap in case someone edited a line they weren't supposed to :)
if [ -n "$javaheap" ] && [[ $javaheap =~ $javaheapre ]]; then
  echo "Setting java heap size to ${javaheap}m..."
  perl -pi -e "s/(^SRV_JAVA_OPTS.*) -Xmx\d+m /\1 -Xmx${javaheap}m /g" /opt/crashplan/bin/run.conf || exit 9
fi


### Enable Remote Management
#Start CrashPlan so it writes my.service.xml, then stop it
echo 'Starting CrashPlan (for just a moment)...'
#/etc/init.d/crashplan start
#/usr/syno/etc/rc.d/S99crashplan.sh start
/opt/etc/init.d/S99crashplan start

[ ! -f /opt/crashplan/conf/my.service.xml ] && echo 'Waiting for my.service.xml to be created...'
while [ ! -f /opt/crashplan/conf/my.service.xml ]; do
sleep 5
done

echo 'Stopping CrashPlan...'
#/etc/init.d/crashplan stop
#/usr/syno/etc/rc.d/S99crashplan.sh stop
/opt/etc/init.d/S99crashplan stop

echo 'Reconfiguring CrashPlan for remote management...'
perl -pi -e 's/<serviceHost>(?:127\.0\.0\.1|localhost)<\/serviceHost>/<serviceHost>0.0.0.0<\/serviceHost>/' /opt/crashplan/conf/my.service.xml || exit 10


### Setup synlink for cpio because upgrade.sh is stupid
echo 'Creating symlink to cpio for future upgrades...'
ln -s /opt/bin/cpio /bin/cpio


### Start CrashPlan
echo 'Starting CrashPlan (finally)...'
#/usr/bin/nohup /etc/init.d/crashplan start
#/usr/bin/nohup /usr/syno/etc/rc.d/S99crashplan.sh start
#/usr/bin/nohup /opt/etc/init.d/S99crashplan start
#screen -mS crashplan $SHELL -c 'echo hi; sleep 3; $SHELL'
/opt/bin/screen -dmS CrashPlan $SHELL -c '/opt/etc/init.d/S99crashplan start; $SHELL'


### Health check
svcport=$(sed -nre '/^\s*<location>/ s/.*:([0-9]+).*/\1/p' /opt/crashplan/conf/my.service.xml)
uiport=$(sed -nre '/^\s*<servicePort>/ s/\s*<servicePort>([0-9]+).*/\1/p' /opt/crashplan/conf/my.service.xml)
echo 'CrashPlan service port:' $svcport
echo 'CrashPlan UI port:' $uiport

echo 'Waiting for service to startup...'
healthcount=0
netstat -anp | grep -qE ":$svcport |:$uiport "
while [ $? -gt 0 ]; do
healthcount=$((healthcount + 1))
if [ $healthcount -gt $maxhealthchecks ]; then
    echo 'Exceeded wait time for CrashPlan to start.  Check CrashPlan log files.'
    break
fi
sleep 5
netstat -anp | grep -qE ":$svcport |:$uiport "
done
if [ $? -eq 0 ]; then
    echo 'CrashPlan has started successfully.'
    netstat -anp | grep -E ":$svcport |:$uiport "
    echo ''
fi

echo 'If all worked well, you should see java listening on 0.0.0.0:'$svcport 'and 0.0.0.0:'$uiport
echo ''
echo 'As of CrashPlan 4.3.0, you will need the GUID below (secrity key) to connect to this instance.'
echo 'If you change the port CrashPlan is listening on, a new GUID will be created.'
echo 'The GUID is located in: /var/lib/crashplan/.ui_info'
echo ''
echo 'CrashPlan .ui_info GUID:' `cat /var/lib/crashplan/.ui_info | awk -F , '{print $2}'`
