emerge   dev-db/mongodb \
  dev-php/pecl-mongo

ln -s /usr/lib/systemd/system/mongodb.service /etc/systemd/system/multi-user.target.wants/
