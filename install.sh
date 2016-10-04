
service ntpd stop
ntpdate -s time.nist.gov
service ntpd start


echo "
                mklabel gpt
                unit mib
                mkpart primary 1 3
                set 1 bios_grub on
                name 1 grub
                mkpart primary 3 131
                name 2 boot
                mkpart primary 131 643
                name 3 swap
                mkpart primary 643 -1
                name 4 rootfs
                print
                quit
              " > /tmp/parted
parted -a optimal /dev/sda < /tmp/parted
rm -f /tmp/parted


mkfs.xfs /dev/sda4
mkdir -p /mnt/gentoo/
mount /dev/sda4 /mnt/gentoo/


mkfs.xfs /dev/sda2
mkdir -p /mnt/gentoo/boot
mount /dev/sda2 /mnt/gentoo/boot


mkswap /dev/sda3
swapon /dev/sda3


cd /mnt/gentoo
wget $( echo http://distfiles.gentoo.org/releases/amd64/autobuilds/`curl http://distfiles.gentoo.org/releases/amd64/autobuilds/latest-stage3-amd64-systemd.txt -q | tail -n 1` )
tar xjpf stage3*.tar.bz2
rm -rf stage3*.tar.bz2
echo "nameserver 8.8.8.8" > /mnt/gentoo/etc/resolv.conf
mount -t proc proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
chroot /mnt/gentoo /bin/bash

mkdir -p /etc/portage/package.accept_keywords

wget 'https://raw.githubusercontent.com/rjkeller/gentoo-bleeding-edge/master/make.conf' -O /etc/portage/make.conf
wget 'https://raw.githubusercontent.com/rjkeller/gentoo-bleeding-edge/master/package.use' -O /etc/portage/package.use/default
wget 'https://raw.githubusercontent.com/rjkeller/gentoo-bleeding-edge/master/package.accept_keywords' -O /etc/portage/package.accept_keywords/default
wget 'https://raw.githubusercontent.com/rjkeller/gentoo-bleeding-edge/master/package.mask' -O /etc/portage/package.mask/default
emerge-webrsync
emerge --sync



echo 'America/Los_Angeles' > /etc/timezone
emerge --config sys-libs/timezone-data


echo 'en_US ISO-8859-1
en_US.UTF-8 UTF-8' > /etc/locale.gen
env-update && source /etc/profile
locale-gen


eselect locale list
eselect locale set en_US.utf8
env-update && source /etc/profile


emerge gentoo-sources
wget https://raw.githubusercontent.com/rjkeller/gentoo-bleeding-edge/master/kernel-vmware-4.3.3.config -O /usr/src/linux/.config
touch /usr/src/linux/.config
cd /usr/src/linux
make oldconfig
make -j4
make modules_install
cp arch/x86_64/boot/bzImage /boot/kernel-`find /usr/src -name linux-4* | awk -Flinux- '{print $NF }'`

emerge --changed-use --deep world
emerge --update --deep --with-bdeps=y @world
emerge @preserved-rebuild

echo '/dev/sda4	/	xfs	noatime	0 1
/dev/sda2	/boot	xfs	noauto,noatime	1 2
/dev/sda3	none	swap	sw	0 0
' > /etc/fstab
rm -rf /etc/mtab
ln -s /proc/self/mounts /etc/mtab

echo 'mdev' > /etc/hostname
echo 'hostname="mdev"' > /etc/conf.d/hostname
echo "127.0.0.1 localhost   mdev
::1     localhost
" > /etc/hosts
cd /etc/conf.d

emerge net-misc/dhcpcd \
  syslog-ng \
  logrotate \
  cronie \
  app-arch/zip \
  app-arch/unzip \
  vim \
  ntp \
  sudo \
  sys-process/htop \
  sys-process/iotop \
  app-misc/screen \
  dev-vcs/git \
  app-admin/eclean-kernel

emerge www-servers/apache \
  dev-lang/php \
  dev-db/redis \
  dev-php/pecl-redis \
  dev-php/phpunit \
  dev-db/mariadb \
  dev-php/xdebug

curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin

systemctl enable syslog-ng
systemctl enable cronie
systemctl enable ntpd
systemctl enable dhcpcd

systemctl enable redis
systemctl enable apache2

# set some git settings
git config --global push.default simple

# Vim auto indent is annoying
sed -i 's/set ai/\"set ai/g' /etc/vim/vimrc

chmod +w /etc/sudoers
echo '%admin ALL=(ALL) ALL
' >> /etc/sudoers
chmod -w /etc/sudoers
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

systemctl enable sshd

emerge dev-db/phpmyadmin
wget 'https://raw.githubusercontent.com/rjkeller/gentoo-bleeding-edge/master/vhosts/00-mdev.conf' -O /etc/apache2/vhosts.d/00-mdev.conf

groupadd admin
useradd -G admin rjkeller
mkdir -p /home/rjkeller/.ssh
chown -R rjkeller:rjkeller /home/rjkeller
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDLeCTbmYcNv0mdubVbrc0Mla8mfAGZw8AnpkLGuG+Tlf7miUF1YoOhYZzzO6dM2LGh113UmZfeD8ArfyUVJ4gteycN5CFYLAPd1Vz4gPAxsgsghjY5e2N/CTCXRes1wxWfWcOjGaVvOeqMl+N6IOfgHbhxxx+slwZcdVHXE7mfLOeDlzs0OC2dtmnvFv0R2tlKF3ds5UZuXJPQ3uHhVQS3WILlKzIcOfpQmz8MGTkwdlwPLH3shX/1Qo+1su8ZMvnJpbE2ctbdB2sYve7o32ExPohtZ+oq+SbqjbMAWSA+zPXPMfcdzT3DjHu1A9ixCoPL7IRsjKdTnhqo8KZtIOUZ rjkeller@rjkellers-MacBook-Pro.local
" > /home/rjkeller/.ssh/authorized_keys
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
echo '456123
456123' | passwd root
echo '456123
456123' | passwd rjkeller

sed -i 's/#SystemMaxUse=/SystemMaxUse=50M/g' /etc/systemd/journald.conf

eselect editor list
eselect editor set 3
env-update && source /etc/profile

emerge dev-python/pip

pip install awscli

emerge dev-ruby/rubygems
eselect ruby set ruby19

gem update system
gem install sass
gem install compass
gem install zurb-foundation



emerge sys-boot/grub

grub-install /dev/sda
echo '
GRUB_CMDLINE_LINUX="init=/usr/lib/systemd/systemd"
' >> /etc/default/grub
echo '
GRUB_CMDLINE_LINUX_DEFAULT="rootfstype=xfs"
' >> /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
