
cp /usr/lib64/libssl.so /usr/lib64/libssl.so.1.0.0
cp /usr/lib64/libcrypto.so /usr/lib64/libcrypto.so.1.0.0
emerge-webrsync
emerge --sync

sed -i 's/mtune=generic/march=native/g' /etc/portage/make.conf
sed -i 's/LDFLAGS/#LDFLAGS/g' /etc/portage/make.conf
sed -i 's/bindist mmx sse sse2//g' /etc/portage/make.conf
echo 'MAKEOPS="-j2"' >> /etc/portage/make.conf

# If you want to boostrap
cd /usr/portage/scripts
./bootstrap.sh
emerge -e system

rm /usr/lib64/libssl.so.1.0.0
rm /usr/lib64/libcrypto.so /usr/lib64/libcrypto.so.1.0.0
emerge dev-libs/openssl
etc-update -q --automode -7