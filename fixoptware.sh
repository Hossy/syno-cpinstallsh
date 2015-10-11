#!/volume1/@optware/bin/bash
ln -s /volume1/@optware /opt
touch /etc/profile
if ! grep '^PATH=.*/opt/bin' /etc/profile >/dev/null 2>&1 ; then
  echo "Modifying PATH in /etc/profile"
  perl -pi -e 's/^(PATH=)(.*?)(?:\/opt\/s?bin:?)?(.*?)(?:\/opt\/s?bin:?)?(.*?)/\1\/opt\/sbin:\/opt\/bin:\2\3\4/' /etc/profile
  #echo "PATH=/opt/sbin:/opt/bin:\$PATH" >> /etc/profile
  #echo "export PATH" >> /etc/profile
fi

if ! grep "^alias ls='ls --color=auto'" /etc/profile >/dev/null 2>&1 ; then
  echo "Adding ls alias to /etc/profile"
  echo "alias ls='ls --color=auto'" >> /etc/profile
fi

if ! grep '^# Optware setup' /etc/rc.local >/dev/null 2>&1
then
  echo "Modifying /etc/rc.local"
  [ ! -e /etc/rc.local ] && echo "#!/bin/sh" >/etc/rc.local
  sed -i -e '/^exit 0/d' /etc/rc.local
  cat >>/etc/rc.local <<EOF

# Optware setup
[ -x /etc/rc.optware ] && /etc/rc.optware start

exit 0
EOF
  chmod 755 /etc/rc.local
fi
