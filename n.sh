#!/bin/bash

#sudo apt install qemu-user-binfmt qemu-system-x86 libguestfs-tools

# note: we cannot use $HOME/xbps/usr/bin:$PATH in the below, as it would be
# expanded as user Nick before the sudo command has set the user root's path
supath=$HOME/xbps/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# set this to today's date to match auto-generated file names
date=20261110

# set this to kernel version (version of the linux7.3 package)
kernel=7.3.3_1

# generate filesystem

sudo rm -rf xbps-cache
sudo sh -c "PATH=$supath ./mkrootfs.sh -r $HOME/src/void-packages/hostdir/binpkgs -z none x86_64-musl"
sudo chown nick:nick void-x86_64-musl-ROOTFS-$date.tar

# modify and repack filesystem
# note: it needs an installed kernel for the /lib/modules directory
# note: services aren't enabled by default and need to be symlinked

sudo rm -rf rootfs
sudo mkdir rootfs
cat void-x86_64-musl-ROOTFS-$date.tar |sudo sh -c "cd rootfs && tar xvf -"
sudo sh -c "PATH=$supath XBPS_ARCH=x86_64-musl xbps-install --cachedir=$HOME/src/void-mklive/xbps-cache/x86_64-musl --repository=$HOME/src/void-packages/hostdir/binpkgs -r rootfs -Uy linux7.3"
sudo ln -s /etc/sv/dhcpcd-eth0 rootfs/etc/runit/runsvdir/current
sudo virt-make-fs --format=qcow2 --size=1G --partition=gpt --type=ext4 --label=rootfs rootfs void-x86_64-musl-ROOTFS-$date.qcow2
sudo chown nick:nick void-x86_64-musl-ROOTFS-$date.qcow2

# generate initrd, extract kernel to use with filesystem

sudo sh -c "PATH=$supath XBPS_ARCH=x86_64-musl xbps-install --cachedir=$HOME/src/void-mklive/xbps-cache/x86_64-musl --repository=$HOME/src/void-packages/hostdir/binpkgs -r rootfs -Uy binutils dracut zstd"
sudo mount -o bind /dev rootfs/dev
sudo mount -o bind /proc rootfs/proc
sudo mount -o bind /sys rootfs/sys
sudo chroot rootfs dracut --force --no-hostonly --zstd --add-drivers ahci --omit systemd /boot/initrd-$kernel
sudo umount rootfs/sys
sudo umount rootfs/proc
sudo umount rootfs/dev
sudo chmod 644 rootfs/boot/initrd-$kernel
cp rootfs/boot/initrd-$kernel rootfs/boot/vmlinuz-$kernel .

# boot filesystem with kernel and initrd

qemu-system-x86_64 -m 1024 -device virtio-blk-pci,drive=hd -drive file=void-x86_64-musl-ROOTFS-$date.qcow2,if=none,id=hd -netdev user,id=net0 -device virtio-net-pci,netdev=net0 -initrd initrd-$kernel -kernel vmlinuz-$kernel -append "root=LABEL=rootfs console=ttyS0" -serial mon:stdio

# generate live ISO

#sudo rm -rf xbps-cache
#sudo sh -c "PATH=$supath ./mklive.sh -a x86_64-musl -r $HOME/src/void-packages/hostdir/binpkgs -v linux7.3"
#sudo chown nick:nick void-live-x86_64-musl-7.3.3_1-$date.iso
#qemu-system-x86_64 -boot d -cdrom void-live-x86_64-musl-7.3.3_1-$date.iso -m 1024
