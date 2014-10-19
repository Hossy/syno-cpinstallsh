#!/opt/bin/bash

if [ ! -n "$1" ]; then
  echo 'Please specify the CrashPlan tgz file.'
  exit 1
fi

if [ ! -r "$1" ]; then
  echo "I can't read that file."
  exit 2
fi

if [[ "$PATH" != */opt/bin:/opt/sbin:/opt/crashplan/jre/bin* ]]; then
  export PATH=/opt/bin:/opt/sbin:/opt/crashplan/jre/bin:$PATH
fi

if [ -x /etc/init.d/crashplan ] && [ -f /opt/crashplan/install.vars ]; then
  echo 'Previous CrashPlan installation detected.  Checking state.'
  if [ "$(/etc/init.d/crashplan status)" != "CrashPlan Engine is stopped." ]; then
    echo 'CrashPlan is not stopped.  Attempting to stop...'
    /etc/init.d/crashplan stop
    if [ "$(/etc/init.d/crashplan status)" != "CrashPlan Engine is stopped." ]; then
      echo 'CrashPlan did not stop.  Cannot install atop a running instance.  Please stop CrashPlan first.'
      exit 3
    fi
  fi
fi

if [ -d /opt/crashplan/upgrade ]; then
  echo "Removing previous version's upgrade files..."
  rm -r /opt/crashplan/upgrade
fi

if [ -d /opt/CrashPlan-install ]; then
  echo 'Removing old install files...'
  rm -r /opt/CrashPlan-install
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

tar -xvf $1 -C /opt

if [ ! -x /opt/CrashPlan-install/install.sh ]; then
  echo 'Failed to extract CrashPlan install files.'
  exit 3
fi

if [ -f /opt/crashplan/install.vars ]; then
  echo 'Setting up for reinstall...'
  rm /opt/crashplan/install.vars || exit 4
fi

echo 'Editing CrashPlan install.sh...'
perl -pi -e 's/#!\/bin\/bash/#!\/opt\/bin\/bash/' /opt/CrashPlan-install/install.sh || exit 5

echo 'Use these settings:'
echo ''
echo -e 'CrashPlan will install to: \e[1;36m/opt\e[0m/crashplan  *** Note: Beginning with CrashPlan 3.6.4, leave off "/crashplan" when entering the path.'
echo -e 'And put links to binaries in: \e[1;36m/opt/bin\e[0m'
echo 'And store datas in: /opt/crashplan/manifest'
echo 'Your init.d dir is: /etc/init.d'
echo -e 'Your current runlevel directory is: \e[1;36m/usr/syno/etc/rc.d\e[0m'
echo ''

cd /opt/CrashPlan-install
./install.sh

if [ "$?" -ne "0" ]; then
  echo 'CrashPlan installation failed.  Cannot continue.'
  exit 6
fi

echo 'Editing files...'

#Edit /etc/init.d/crashplan
#sed -i 's/#!\/bin\/sh/#!\/opt\/bin\/bash/' /usr/syno/etc/rc.d/S99crashplan || exit 7
mv /usr/syno/etc/rc.d/S99crashplan /usr/syno/etc/rc.d/S99crashplan.sh || exit 7
perl -pi.bak -e 's/SCRIPTNAME=(?!env\\ PATH=\/opt\/bin:\/opt\/sbin:\${PATH}\\ )/SCRIPTNAME=env\\ PATH=\/opt\/bin:\/opt\/sbin:\${PATH}\\ /' /etc/init.d/crashplan || exit 7

#Edit /opt/crashplan/bin/CrashPlanEngine
perl -pi.bak -e 's/#!\/bin\/bash/#!\/opt\/bin\/bash/' /opt/crashplan/bin/CrashPlanEngine || exit 7
perl -pi -e "s/ps (?:-eo 'pid,cmd'|-p)( ?)/ps\1/" /opt/crashplan/bin/CrashPlanEngine || exit 7
perl -pi -e 's/(\s*)nice /\1\/opt\/bin\/nice /' /opt/crashplan/bin/CrashPlanEngine || exit 7

#Edit for open file count
sed -i 'N;N;/#############################################################\n/a\
# Increase open files limit\
ulimit -n 131072\
' /opt/crashplan/bin/CrashPlanEngine
### -- uncomment if you have additional memory installed --
sed -i '/SRV_JAVA_OPTS/s/ -Xmx512m / -Xmx1536m /g' /opt/crashplan/bin/run.conf

echo 'Starting CrashPlan...'
#/etc/init.d/crashplan start
/usr/syno/etc/rc.d/S99crashplan.sh start

echo 'Waiting 5s...'
sleep 5

echo 'Stopping CrashPlan...'
#/etc/init.d/crashplan stop
/usr/syno/etc/rc.d/S99crashplan.sh stop

echo 'Reconfiguring CrashPlan for remote management...'
perl -pi -e 's/<serviceHost>127.0.0.1<\/serviceHost>/<serviceHost>0.0.0.0<\/serviceHost>/' /opt/crashplan/conf/my.service.xml

echo 'Starting CrashPlan...'
/usr/bin/nohup /etc/init.d/crashplan start
#/usr/bin/nohup /usr/syno/etc/rc.d/S99crashplan.sh start

echo 'Waiting 30s...'
sleep 30

echo 'Checking ports...'
netstat -anp | grep ':424.'

echo 'As of DSM 4.3, nohup is not working.  This means once you exit this shell, CrashPlan will close.'
echo 'You will need to restart your NAS to allow CrashPlan to start outside this shell.'
