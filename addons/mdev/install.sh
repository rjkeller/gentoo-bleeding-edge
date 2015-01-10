emerge dev-php/pecl-memcache \
  net-libs/nodejs \
  net-misc/memcached

echo '[Unit]
Description=Memcached
After=network.target

[Service]
Type=simple
User=memcached

# Note: we set --basedir to prevent probes that might trigger SELinux alarms,
# https://bugzilla.redhat.com/show_bug.cgi?id=547485
ExecStart=/usr/bin/memcached

[Install]
WantedBy=multi-user.target
' > /usr/lib/systemd/system/memcached.service

ln -s /usr/lib/systemd/system/memcached.service /etc/systemd/system/multi-user.target.wants/

gem install scss-lint

npm install -g gulp
npm install -g gulp-notify

