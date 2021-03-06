
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
parted -a optimal /dev/vda < /tmp/parted
rm -f /tmp/parted


mkfs.ext4 /dev/vda4
mkdir -p /mnt/gentoo/
mount /dev/vda4 /mnt/gentoo/


mkfs.ext4 /dev/vda2
mkdir -p /mnt/gentoo/boot
mount /dev/vda2 /mnt/gentoo/boot


mkswap /dev/vda3
swapon /dev/vda3


cd /mnt/gentoo
wget $( echo http://distfiles.gentoo.org/releases/amd64/autobuilds/`curl http://distfiles.gentoo.org/releases/amd64/autobuilds/latest-stage3-amd64-nomultilib.txt -q | tail -n 1` )
tar xjpf stage3*.tar.bz2
rm -rf stage3*.tar.bz2
echo "nameserver 8.8.8.8" > /mnt/gentoo/etc/resolv.conf
mount -t proc proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
chroot /mnt/gentoo /bin/bash


wget 'https://raw.githubusercontent.com/rjkeller/gentoo-bleeding-edge/master/make.conf' -O /etc/portage/make.conf
wget 'https://raw.githubusercontent.com/rjkeller/gentoo-bleeding-edge/master/package.use' -O /etc/portage/package.use
wget 'https://raw.githubusercontent.com/rjkeller/gentoo-bleeding-edge/master/package.accept_keywords' -O /etc/portage/package.accept_keywords
wget 'https://raw.githubusercontent.com/rjkeller/gentoo-bleeding-edge/master/package.mask' -O /etc/portage/package.mask


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
wget https://raw.githubusercontent.com/rjkeller/gentoo-bleeding-edge/master/kernel-virtio-3.15.config -O /usr/src/linux/.config
touch /usr/src/linux/.config
cd /usr/src/linux
make
make modules_install
cp arch/x86_64/boot/bzImage /boot/kernel-`find /usr/src -name linux-3* | awk -Flinux- '{print $NF }'`


echo '
sys-apps/dbus -systemd' >> /etc/portage/package.use
emerge systemd
sed -i 's/sys-apps\/dbus -systemd/ /g' /etc/portage/package.use
emerge sys-apps/dbus


emerge --update --deep --with-bdeps=y @world
emerge @preserved-rebuild
emerge --changed-use --deep world


echo '/dev/vda4	/	ext4	noatime	0 1
/dev/vda2	/boot	ext4	noauto,noatime	1 2
/dev/vda3	none	swap	sw	0 0
' > /etc/fstab
rm -rf /etc/mtab
ln -s /proc/self/mounts /etc/mtab


echo 'techdev02.yliving.net' > /etc/hostname
echo 'hostname="techdev02.yliving.net"' > /etc/conf.d/hostname
echo "127.0.0.1 localhost   techdev02.yliving.net
::1     localhost
" > /etc/hosts
cd /etc/conf.d
echo "[Unit]
Description=DHCP
After=basic.target

[Service] 
Type=oneshot 
RemainAfterExit=yes 
ExecStart=/sbin/dhcpcd

[Install] 
WantedBy=multi-user.target
" > /usr/lib/systemd/system/network.dhcp.service
ln -s /usr/lib/systemd/system/network.dhcp.service /etc/systemd/system/multi-user.target.wants/

emerge net-misc/dhcpcd syslog-ng logrotate cronie app-admin/puppet

# DEV ONLY!
emerge app-arch/zip app-arch/unzip vim ntp sudo www-servers/apache sys-process/htop sys-process/iotop php app-misc/screen mariadb dev-vcs/git dev-vcs/subversion

emerge dev-php/phpunit dev-php/xdebug



ln -s /usr/lib/systemd/system/syslog-ng.service /etc/systemd/system/syslog.service
ln -s /usr/lib/systemd/system/syslog-ng.service /etc/systemd/system/multi-user.target.wants/
ln -s /usr/lib/systemd/system/cronie.service /etc/systemd/system/multi-user.target.wants/
ln -s /usr/lib/systemd/system/ntpd.service /etc/systemd/system/multi-user.target.wants/

# Vim auto indent is annoying
sed -i 's/set ai/\"set ai/g' /etc/vim/vimrc

chmod +w /etc/sudoers
echo '%admin ALL=(ALL) ALL
' >> /etc/sudoers
chmod -w /etc/sudoers
ln -s /usr/lib/systemd/system/apache2.service /etc/systemd/system/multi-user.target.wants/
echo '

#SERVER SETTINGS
ServerName techdev02.yliving.net
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

sed -i 's/-D DEFAULT_VHOST -D INFO/-D DEFAULT_VHOST -D INFO -D PHP5/g' /etc/conf.d/apache2

ln -s /usr/lib/systemd/system/sshd.service /etc/systemd/system/multi-user.target.wants/


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


eselect editor list
eselect editor set 3
env-update && source /etc/profile


emerge sys-boot/grub

grub2-install /dev/vda
echo '
GRUB_CMDLINE_LINUX="init=/usr/lib/systemd/systemd"
' >> /etc/default/grub
echo '
GRUB_CMDLINE_LINUX_DEFAULT="rootfstype=ext4"
' >> /etc/default/grub
grub2-mkconfig -o /boot/grub/grub.cfg
