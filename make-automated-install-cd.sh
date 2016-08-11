#!/bin/bash

# edit these 3 variables if you want to try another distro. create an md5sum
# file with something like 
#   md5sum $ISO > $ISO.MD5SUM
ISO=ubuntu-16.04.1-server-amd64.iso
OUTPUT=autoinstall-ubuntu-16.04.1-server-amd64.iso
URL=http://releases.ubuntu.com/16.04.1/ubuntu-16.04.1-server-amd64.iso

MOUNT=iso-mount-dir
WORK=iso-work-dir

ISOHDPFX=/usr/share/syslinux/isohdpfx.bin

if [ ! -f $ISOHDPFX ]; then
    echo 'trying to locate isohdpfx.bin'
    ISOHDPFX=`locate isohdpfx.bin`
fi

if [ ! -f $ISOHDPFX ]; then
    echo 'Could not find isohdpfx.bin on this system'
    exit 1
fi

command -v xorriso &> /dev/null
if [ $? != 0  ]; then
    echo 'Could not find `xorriso` in path required for iso creation.'
    exit 1
fi

# if we don't have iso or it doesnt' match md5sum, fetch it
if [ ! -f $ISO ]  || !  md5sum -c ./MD5SUMS
then
    rm -f $ISO
	wget $URL
    # if we still don't gots it, die
    if [ ! -f $ISO ]  || !  md5sum -c $ISO.MD5SUM 
    then
        echo "Could not download iso?"
        exit 1
    fi
fi

# clean up after interruptted runs.  if this fails, it's because the mount
# point is still mounted, so manually unmount please.
rm -rf $MOUNT $WORK

# make mount point, mount it with sudo, copy over contents because ISO's
# can only be mounted readonly
mkdir -p $MOUNT $WORK
sudo mount -o ro,loop $ISO $MOUNT
cp -rT $MOUNT $WORK
chmod -R a+w $WORK

# copy files over to image
cp ks.cfg $WORK/
cp grub.cfg $WORK/boot/grub
# bugs.launchpad.net/ubuntu/+source/debian-installer/+bug/1347726
echo 'd-i preseed/early_command string umount /media || true' >> $WORK/preseed/ubuntu-server.seed

# magic mkiso incantation
xorriso -as mkisofs \
    -isohybrid-mbr /usr/share/syslinux/isohdpfx.bin \
    -c isolinux/boot.cat \
    -b isolinux/isolinux.bin \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -eltorito-alt-boot \
    -e boot/grub/efi.img \
    -no-emul-boot \
    -isohybrid-gpt-basdat \
    -o $OUTPUT \
    $WORK

# clean up after ourselves
sudo umount $MOUNT
rm -rf $MOUNT $WORK
