mkdir /etc/portage/repos.conf
echo '[gentoo]
location = /usr/portage
sync-type = rsync
sync-uri = rsync://LOCAL_RSYNC_IP/gentoo-portage
auto-sync = yes
' > /etc/portage/repos.conf/gentoo.conf

emerge --sync
