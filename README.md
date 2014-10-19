syno-cpinstallsh 1.1 by Hossy

Verified on DSM version: DSM 4.3-3827


PREREQUISITES
#############
Synology NAS
ipkg installed (http://forum.synology.com/wiki/index.php/How_to_Install_Bootstrap)


NOTES
#####
I have removed the /opt mount that the bootstrap install creates as it prevents the
DSM from working properly: I have verified that upgrades and volume creation fail
with the /opt mount.

To remove the /opt mount:
1. umount /opt
2. ln -s /volume1/@optware /opt


FILES
#####
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
fixoptware.sh
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
After a DSM upgrade, the /opt softlink is lost as well as other customizations. 
This script restores them.

NOTE: This needs to be run first after any DSN upgrade where you've lost /opt.

Usage:

./fixoptware.sh

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
optpath.sh
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
When logging in as root, the modifications fixoptware.sh makes to /etc/profile to
update PATH don't work.  I'm still working on figuring this out.  optpath.sh can
be used to add /opt/bin:/opt/sbin to your PATH.

Usage:

source optpath.sh

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SynoCrashPlanInstall.sh:
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
This script automates (as much as possible) of the CrashPlan install on subsequent
modifications. Before running the install, the script provides you the path
information to provide the CrashPlan install script.
After installation, this script enables CrashPlan for remote management so you
don't have to use the SSH tunnel as described on CrashPlan's web site (you can
still use it if you want, though).

Usage:

./SynoCrashPlanInstall.sh <CrashPlan-tgz-file>


REMOTE MANAGEMENT FROM WINDOWS CLIENT
#####################################
I have created a batch script to make remote management easy from Windows.  Check
out: https://github.com/Hossy/win-crashplan-uiswitcher


COPYRIGHT
#########
Copyright 2014 @Hossy

syno-cpinstallsh is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.