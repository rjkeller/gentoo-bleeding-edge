
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


mkfs.ext4 /dev/sda4
mkdir -p /mnt/gentoo/
mount /dev/sda4 /mnt/gentoo/


mkfs.ext4 /dev/sda2
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
mkdir -p /etc/portage/package.use
mkdir -p /etc/portage/package.mask

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

# If you want to boostrap
cd /usr/portage/scripts
./bootstrap.sh
emerge -e system
emerge -e world

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

echo '/dev/sda4	/	ext4	noatime	0 1
/dev/sda2	/boot	ext4	noauto,noatime	1 2
/dev/sda3	none	swap	sw	0 0
' > /etc/fstab
rm -rf /etc/mtab
ln -s /proc/self/mounts /etc/mtab

echo 'epikdev' > /etc/hostname
echo 'hostname="epikdev"' > /etc/conf.d/hostname
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

systemctl enable syslog-ng
systemctl enable cronie
systemctl enable ntpd
systemctl enable dhcpcd

emerge www-servers/nginx \
  net-libs/nodejs \
  dev-db/redis \
  dev-db/mariadb

systemctl enable redis
systemctl enable nginx


# set some git settings
git config --global push.default simple

# Vim auto indent is annoying
sed -i 's/set ai/\"set ai/g' /etc/vim/vimrc

chmod +w /etc/sudoers
echo '%admin ALL=(ALL) ALL
' >> /etc/sudoers
chmod -w /etc/sudoers
systemctl enable sshd

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

emerge dev-python/awscli


sed -i 's/slaac private/# slaac private/g' /etc/dhcpcd.conf


systemd-machine-id-setup

emerge sys-boot/grub

grub-install /dev/sda
echo '
GRUB_CMDLINE_LINUX="init=/usr/lib/systemd/systemd"
' >> /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
