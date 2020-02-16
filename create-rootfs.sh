#!/bin/sh

set -e

basedir=$(dirname $(readlink -f $0))
. ${basedir}/config/env.sh

echo -n "Removing existing ${rootfs}, press ENTER to proceed... "
read input

echo -n "Creating rootfs... "
qemu-img create ${basedir}/rootfs.img ${rootfs_size} >> ${basedir}/log
mkfs.ext4 ${basedir}/rootfs.img >> ${basedir}/log

if [ ! -e ${rootfs} ]; then
  sudo mkdir ${rootfs}
fi

echo -n "Mounting ${rootfs} on loopback... "
sudo mount -o loop ${basedir}/rootfs.img ${rootfs}
echo "ok"

echo -n "Bootstrapping filesystem... "
$(sudo debootstrap unstable ${rootfs} http://deb.debian.org/debian/ >> ${basedir}/log)
echo "ok"

echo -n "Setting hostname: ${hostname}... "
sudo bash -c "echo '${hostname}' > ${rootfs}/etc/hostname"
echo "ok"

echo "Set the root password... "
sudo bash -c "chroot ${rootfs} passwd root"

echo "Enabling networking... "
sudo cp ${confdir}/dhcp.network ${rootfs}/etc/systemd/network/
sudo bash -c "chroot ${rootfs} systemctl enable systemd-networkd.service"
sudo bash -c "chroot ${rootfs} systemctl enable systemd-resolved.service"

echo -n "Cleaning up... "
sync
sleep 5
sudo umount ${rootfs}
sudo rmdir ${rootfs}
echo "ok"
