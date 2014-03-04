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

if [ -d /opt/CrashPlan-install ]; then
  echo 'Removing old install files...'
  rm -r /opt/CrashPlan-install
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
sed -i 's/#!\/bin\/bash/#!\/opt\/bin\/bash/' /opt/CrashPlan-install/install.sh || exit 5

echo 'Use these settings:'
echo ''
echo -e 'CrashPlan will install to: \e[1;36m/opt/crashplan\e[0m'
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
sed -i 's/ps -eo /ps /' /opt/crashplan/bin/CrashPlanEngine;sed -i 's/ps -p /ps /' /opt/crashplan/bin/CrashPlanEngine; sed -i "s/ps 'pid,cmd'/ps/" /opt/crashplan/bin/CrashPlanEngine || exit 7
sed -i 's/#!\/bin\/sh/#!\/opt\/bin\/bash/' /usr/syno/etc/rc.d/S99crashplan || exit 7
sed -i 's/#!\/bin\/bash/#!\/opt\/bin\/bash/' /opt/crashplan/bin/CrashPlanEngine || exit 7
sed -i 's/	nice /\	\/opt\/bin\/nice /' /opt/crashplan/bin/CrashPlanEngine || exit 7
sed -i 's/SCRIPTNAME=(?!env\\ PATH=\/opt\/bin:\/opt\/sbin:$PATH\\ )/SCRIPTNAME=env\\ PATH=\/opt\/bin:\/opt\/sbin:$PATH\\ /' /usr/syno/etc/rc.d/S99crashplan || exit 7

#Edit for open file count
sed -i 'N;N;/#############################################################\n/a\
# Increase open files limit\
ulimit -n 131072\
' /opt/crashplan/bin/CrashPlanEngine
### -- uncomment if you have additional memory installed --
#sed -i '/SRV_JAVA_OPTS/s/ -Xmx512m / -Xmx1536m /g' /opt/crashplan/bin/run.conf

echo 'Starting CrashPlan...'
/usr/syno/etc/rc.d/S99crashplan start

echo 'Waiting 5s...'
sleep 5

echo 'Stopping CrashPlan...'
/usr/syno/etc/rc.d/S99crashplan stop

echo 'Reconfiguring CrashPlan for remote management...'
sed -i 's/<serviceHost>127.0.0.1<\/serviceHost>/<serviceHost>0.0.0.0<\/serviceHost>/' /opt/crashplan/conf/my.service.xml

echo 'Starting CrashPlan...'
nohup /usr/syno/etc/rc.d/S99crashplan start

echo 'Waiting 30s...'
sleep 30

echo 'Checking ports...'
netstat -anp | grep ':424.'
