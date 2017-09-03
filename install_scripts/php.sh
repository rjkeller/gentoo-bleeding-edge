
emerge www-servers/apache \
  dev-lang/php \
  dev-db/redis \
  dev-php/pecl-redis \
  dev-php/phpunit \
  dev-db/mariadb \
  dev-php/xdebug

curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin


echo '

#SERVER SETTINGS
ServerName mdev
KeepAlive On
MaxKeepAliveRequests 100
KeepAliveTimeout 15

StartServers       8
MinSpareServers    5
MaxSpareServers   20
ServerLimit      256
MaxClients       256
MaxRequestsPerChild  4000

Listen 80
Listen 443
' >> /etc/apache2/httpd.conf
sed -i 's/-D DEFAULT_VHOST -D INFO/-D DEFAULT_VHOST -D INFO -D PHP/g' /etc/conf.d/apache2

sed -i 's/allow_url_fopen = On/allow_url_fopen = Off/g' /etc/php/apache2-php5.6/php.ini


emerge dev-db/phpmyadmin
wget 'https://raw.githubusercontent.com/rjkeller/gentoo-bleeding-edge/master/vhosts/00-mdev.conf' -O /etc/apache2/vhosts.d/00-mdev.conf


emerge dev-ruby/rubygems
eselect ruby set ruby19

gem update system
gem install sass
gem install compass
gem install zurb-foundation
