#!/volume1/@optware/bin/bash
ln -s /volume1/@optware /opt
touch /etc/profile
if ! grep '^PATH=.*/opt/bin' /etc/profile >/dev/null 2>&1 ; then
  echo "Modifying /etc/profile"
  echo "PATH=/opt/bin:/opt/sbin:\$PATH" >> /etc/profile
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
