emerge www-servers/nginx \
  net-libs/nodejs \
  dev-db/redis \
  dev-db/mariadb

systemctl enable redis
systemctl enable nginx
