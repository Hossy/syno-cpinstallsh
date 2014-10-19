syno-cpinstallsh 1.2 by Hossy
=====================================

A CrashPlan installer for Synology NAS.

Verified on DSM version: DSM 4.3-3827 Update 8


Prerequisites
-------------
- Synology NAS
- ipkg installed (<http://forum.synology.com/wiki/index.php/How_to_Install_Bootstrap>)


Notes
-----
I have removed the /opt mount that the bootstrap install creates as it prevents the
DSM from working properly: I have verified that upgrades and volume creation fail
with the /opt mount.

To remove the /opt mount:

1. umount /opt
2. ln -s /volume1/@optware /opt


Files
-----

### fixoptware.sh ###

After a DSM upgrade, the /opt softlink is lost as well as other customizations. 
This script restores them.

NOTE: This needs to be run first after any DSM upgrade where you've lost /opt.

Usage:

    ./fixoptware.sh

### optpath.sh ###

When logging in as root, the modifications fixoptware.sh makes to /etc/profile to
update PATH don't work.  I'm still working on figuring this out.  optpath.sh can
be used to add /opt/bin:/opt/sbin to your PATH.

Usage:

    source optpath.sh

### SynoCrashPlanInstall.sh ###

This script automates (as much as possible) of the CrashPlan install on subsequent
modifications. Before running the install, the script provides you the path
information to provide the CrashPlan install script.

After installation, this script enables CrashPlan for remote management so you
don't have to use the SSH tunnel as described on CrashPlan's web site (you can
still use it if you want, though).

Usage:

    ./SynoCrashPlanInstall.sh <CrashPlan-tgz-file>

#### Java Heap Size ####

For those of us who have very large backup sets, the default java heap size may not
be enough to keep CrashPlan from crashing due to Out of Memory errors.  This is a
known issue and this script will help you adjust your system, if you have the
capacity.  In CrashPlan 3.6.3, the default maximum java heap size is 1024MB (it was
increased in the recent past from 512MB to 1024MB).  However, sometimes that is not
enough.  If this is the case for you, this script provides a method of updating the
maximum java heap size by editing this file and uncommenting `#javaheap=2048` in
the beginning of the file and changing the value to whatever you need.  I have 3GB
of RAM in my Synology NAS, so I allow CrashPlan to consume up to 2GB.  The value is
always specified in MB, but please ensure you provide numbers only.

**WARNING:** If you're going to edit the script, please only edit the javaheap line
at the top.  If you edit the script on Windows, make sure you use an editor like
Notepad++ (*not* Notepad) that will respect Linux EOL style.

Obviously, you will need to ensure your NAS has the physical memory available.
Synology recommends you purchase your memory upgrade from them (of course), but you
don't have to if you know what you're doing (or think you do).  The Synology Wiki
has a good article on user-reported compatible RAM modules here:
<http://forum.synology.com/wiki/index.php/User_Reported_Compatible_RAM_modules>.

For more information on Out of Memory issues with CrashPlan, see
<http://support.code42.com/CrashPlan/Latest/Troubleshooting/CrashPlan_Runs_Out_Of_Memory_And_Crashes>.


Remote Management from Windows Client
-------------------------------------
I have created a batch script to make remote management easy from Windows.  Check
out: <https://github.com/Hossy/win-crashplan-uiswitcher>


Copyright
---------
Copyright 2012-2014 Hossy

`syno-cpinstallsh` is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

`syno-cpinstallsh` is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with `syno-cpinstallsh`.  If not, see <http://www.gnu.org/licenses/>.

Change Log
----------
### v1.2 ###
- Fixed bug in CrashPlan verification where script would not proceed if there was
  an error checking the status
- Changed java heap sed command to be dynamic with CrashPlan updates
- Changed/Grouped exit codes to make more sense
- Added java heap option at the top of the script to make it easier to use
- Added documentation in README for java heap setting
- Added comments to script

### v1.1 build 2 ###
- Fixed java heap option (CrashPlan changed from 512MB to 1024MB by default)

### v1.1 ###

- Added protection to stop CrashPlan before attempting to install
- Added removal of CrashPlan upgrade directory before installation (for cleanup)
- Added removal of CrashPlanDesktop symlink (for cleanup)
- Added removal of both old and new rc.d symlinks
  - install.sh will recreate the non .sh one and then this script will rename it
  - Fixes a bug where the rc.d script and init.d script were actual files and not
    symlink and file combo
- Replaced string substitutions with perl commands instead of sed
  - .bak files are now created
- Starting and stopping CrashPlan is now done via the init.d script instead of rc.d
- Misc on-screen instruction updates

### v1.0 - Mar 4, 2014 #2 ###
- Fixed java path logic
- Replaced die with exit
- Script now terminates if CrashPlan install fails
- Cleaned up comments

### v1.0 - Mar 4, 2014 ###
- Fixed PATH to prevent constant reinstall of java
- Fixed sed command for S99crashplan to prevent endless PATH entries
- Added ulimit to increase open files limit
- Added comment for adjusting java memory allocation (NOTE: Additional RAM required)
- Added PID display to netstat at the end

### v1.0 ###
- Initial commit