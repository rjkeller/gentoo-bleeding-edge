
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
  mkpart primary 131 387
  name 3 swap
  mkpart primary 387 -1
  name 4 rootfs
  print
  quit
" > /tmp/parted
parted -a optimal DEFAULT_DISK < /tmp/parted
rm -f /tmp/parted


mkfs.DEFAULT_FILE_SYSTEM DEFAULT_DISK4
mkdir -p /mnt/gentoo/
mount DEFAULT_DISK4 /mnt/gentoo/


mkfs.DEFAULT_FILE_SYSTEM DEFAULT_DISK2
mkdir -p /mnt/gentoo/boot
mount DEFAULT_DISK2 /mnt/gentoo/boot


mkswap DEFAULT_DISK3
swapon DEFAULT_DISK3


cd /mnt/gentoo

UNTAR_STEP

cp --dereference /etc/resolv.conf /mnt/gentoo/etc/

mount -t proc proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev

chroot /mnt/gentoo /bin/bash
source /etc/profile

mkdir -p /etc/portage/package.accept_keywords
mkdir -p /etc/portage/package.use
mkdir -p /etc/portage/package.mask

INIT_STEP

wget 'https://raw.githubusercontent.com/rjkeller/gentoo-bleeding-edge/master/portage/make.conf' -O /etc/portage/make.conf
wget 'https://raw.githubusercontent.com/rjkeller/gentoo-bleeding-edge/master/portage/package.use' -O /etc/portage/package.use/default
wget 'https://raw.githubusercontent.com/rjkeller/gentoo-bleeding-edge/master/portage/package.accept_keywords' -O /etc/portage/package.accept_keywords/default
wget 'https://raw.githubusercontent.com/rjkeller/gentoo-bleeding-edge/master/portage/package.mask' -O /etc/portage/package.mask/default

sed -i 's/EXTRA_USE_FLAGS/DEFAULT_EXTRA_USE_FLAGS/g' /etc/portage/make.conf
sed -i 's/CORE_COUNT/DEFAULT_CORE_COUNT/g' /etc/portage/make.conf

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
wget https://raw.githubusercontent.com/rjkeller/gentoo-bleeding-edge/master/kernels/kernel-virtualbox-4.9.config -O /usr/src/linux/.config
touch /usr/src/linux/.config
cd /usr/src/linux
make oldconfig
make -jDEFAULT_CORE_COUNT
make modules_install
cp arch/x86_64/boot/bzImage /boot/kernel-`find /usr/src -name linux-4* | awk -Flinux- '{print $NF }'`

emerge --update --deep --newuse --with-bdeps=y @world
emerge @preserved-rebuild

echo 'DEFAULT_DISK4 / DEFAULT_FILE_SYSTEM noatime 0 1
DEFAULT_DISK2 /boot DEFAULT_FILE_SYSTEM noauto,noatime  1 2
DEFAULT_DISK3 none  swap  sw  0 0
' > /etc/fstab
rm -rf /etc/mtab
ln -s /proc/self/mounts /etc/mtab

echo 'DEFAULT_HOST_NAME' > /etc/hostname
echo 'hostname="DEFAULT_HOST_NAME"' > /etc/conf.d/hostname
echo "127.0.0.1 localhost DEFAULT_HOST_NAME
::1     localhost DEFAULT_HOST_NAME
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

DEFAULT_SCRIPT_SETUP

emerge dev-python/awscli

sed -i 's/slaac private/# slaac private/g' /etc/dhcpcd.conf
systemd-machine-id-setup

emerge sys-boot/grub

grub-install DEFAULT_DISK
echo '
GRUB_CMDLINE_LINUX="init=/usr/lib/systemd/systemd"
' >> /etc/default/grub
echo '
GRUB_CMDLINE_LINUX_DEFAULT="rootfstype=DEFAULT_FILE_SYSTEM"
' >> /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
