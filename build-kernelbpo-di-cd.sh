#! /bin/bash

DEBIAN_TARGET_DIST=stretch
PACKAGES_NEEDED="git simple-cdd"
MUH_REGEX="[0-9]+\.[0-9]+\.[0-9]+\-[0-9]+\.bpo\.[0-9]"
#going to make 2 wild assumptions, local system has backports and apt-cache will list the latest (bpo) version at the top
BPO_KP=$(apt-cache show linux-image-amd64 | grep -m 1 Depends | cut -c 10-)
BPO_KV=$(echo ${BPO_KP} | egrep -o ${MUH_REGEX})

#install things we need
sudo apt-get build-dep packagename
sudo apt install $PACKAGES_NEEDED

#do eveything in /tmp
cd /tmp

#get the right debian installer source
git clone https://anonscm.debian.org/git/d-i/debian-installer.git -b $DEBIAN_TARGET_DIST

#make the source list file for di
echo "deb http://deb.debian.org/debian ${DEBIAN_TARGET_DIST} main/debian-installer" > debian-installer/build/sources.list.udeb.local
echo "deb http://deb.debian.org/debian ${DEBIAN_TARGET_DIST}-backports main/debian-installer" >> debian-installer/build/sources.list.udeb.local

#configure di to make a di using backported stuff
echo "LINUX_KERNEL_ABI = ${BPO_KV}" > debian-installer/build/config/local
echo "USE_UDEBS_FROM = ${DEBIAN_TARGET_DIST}-backports" >> debian-installer/build/config/local

cd debian-installer/build

#clean stuff up
make reallyclean

#make a the right bits of di
fakeroot make build_cdrom_isolinux

cd ../..

#time to do simple-cdd things
mkdir -p simple-cdd-tmp/profiles

cd simple-cdd-tmp

#blank out the default preseed file as it's a bit bad
echo "" > profiles/default.preseed

echo "backports=\"true\"" > profiles/${DEBIAN_TARGET_DIST}-bpokernel.conf
echo "backports_packages=\"linux-image-amd64 ${BPO_KP}\"" >>  profiles/${DEBIAN_TARGET_DIST}-bpokernel.conf
echo "mirror_components=\"main contrib non-free\"" >>  profiles/${DEBIAN_TARGET_DIST}-bpokernel.conf
echo "FORCE_FIRMWARE=1" >>  profiles/${DEBIAN_TARGET_DIST}-bpokernel.conf
echo "extra_udeb_dist=${DEBIAN_TARGET_DIST}-backports" >>  profiles/${DEBIAN_TARGET_DIST}-bpokernel.conf
echo "DI_DIR=\"/tmp/debian-installer/build/dest/\"" >>  profiles/${DEBIAN_TARGET_DIST}-bpokernel.conf

simple-cdd --profiles ${DEBIAN_TARGET_DIST}-bpokernel --dist ${DEBIAN_TARGET_DIST} --auto-profiles ${DEBIAN_TARGET_DIST}-bpokernel
