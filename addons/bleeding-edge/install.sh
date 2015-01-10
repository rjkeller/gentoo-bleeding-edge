emerge dev-db/mariadb

ln -s /usr/lib/systemd/system/mysqld.service /etc/systemd/system/multi-user.target.wants/

echo "456123
456123" | emerge --config dev-db/mariadb

