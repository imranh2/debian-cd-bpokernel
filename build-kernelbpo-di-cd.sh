#! /bin/bash

DEBIAN_TARGET_DIST=$(cat /etc/*-release | grep "VERSION_CODENAME=" | sed s/VERSION_CODENAME=//)
PACKAGES_NEEDED="git simple-cdd fakeroot"
MUH_REGEX="[0-9]+\.[0-9]+\.[0-9]+\-[0-9]+\.bpo\.[0-9]"
#going to make 2 wild assumptions, local system has backports and apt-cache will list the latest (bpo) version at the top
BPO_KP=$(apt-cache show linux-image-amd64 | grep -m 1 Depends | cut -c 10-)
BPO_KV=$(echo ${BPO_KP} | egrep -o ${MUH_REGEX})

#install things we need
sudo apt-get build-dep debian-installer simple-cdd -y
sudo apt install $PACKAGES_NEEDED -y

#do eveything in /tmp
cd /tmp

#get the right debian installer source
#git clone https://salsa.debian.org/installer-team/debian-installer -b $DEBIAN_TARGET_DIST
apt-get source debian-installer
ln -s debian-installer-*/ debian-installer

#make the source list file for di
echo "deb http://deb.debian.org/debian ${DEBIAN_TARGET_DIST} main/debian-installer" > debian-installer/build/sources.list.udeb.local
echo "deb http://deb.debian.org/debian ${DEBIAN_TARGET_DIST} contrib/debian-installer" >> debian-installer/build/sources.list.udeb.local
echo "deb http://deb.debian.org/debian ${DEBIAN_TARGET_DIST} non-free/debian-installer" >> debian-installer/build/sources.list.udeb.local
echo "deb http://deb.debian.org/debian ${DEBIAN_TARGET_DIST}-updates main/debian-installer" >> debian-installer/build/sources.list.udeb.local
echo "deb http://deb.debian.org/debian ${DEBIAN_TARGET_DIST}-updates contrib/debian-installer" >> debian-installer/build/sources.list.udeb.local
echo "deb http://deb.debian.org/debian ${DEBIAN_TARGET_DIST}-updates non-free/debian-installer" >> debian-installer/build/sources.list.udeb.local
echo "deb http://deb.debian.org/debian ${DEBIAN_TARGET_DIST}-backports main/debian-installer" >> debian-installer/build/sources.list.udeb.local
echo "deb http://deb.debian.org/debian ${DEBIAN_TARGET_DIST}-backports contrib/debian-installer" >> debian-installer/build/sources.list.udeb.local
echo "deb http://deb.debian.org/debian ${DEBIAN_TARGET_DIST}-backports non-free/debian-installer" >> debian-installer/build/sources.list.udeb.local

#configure di to make a di using backported stuff
echo "LINUX_KERNEL_ABI = ${BPO_KV}" > debian-installer/build/config/local
echo "USE_UDEBS_FROM = ${DEBIAN_TARGET_DIST}-backports" >> debian-installer/build/config/local

cd debian-installer/build

#clean stuff up
make reallyclean

#make a the right bits of di
echo "fakeroot make build cdrom isolinux"
fakeroot make build_cdrom_isolinux
echo "fakeroot make build cdrom isolinux FINISHED"


cd ../..

#time to do simple-cdd things
mkdir -p simple-cdd-tmp/profiles

cd simple-cdd-tmp

#blank out the default preseed file as it's a bit bad
echo "" > profiles/default.preseed

#enable backports, contrib, and non-free
echo "d-i apt-setup/services-select multiselect backports" > profiles/${DEBIAN_TARGET_DIST}-bpoknl.preeseed
echo "d-i apt-setup/contrib boolean true" >> profiles/${DEBIAN_TARGET_DIST}-bpoknl.preeseed
echo "d-i apt-setup/non-free boolean true" >> profiles/${DEBIAN_TARGET_DIST}-bpoknl.preseed

echo "backports=true" > profiles/${DEBIAN_TARGET_DIST}-bpoknl.conf
echo "backports_packages=\"linux-image-amd64 ${BPO_KP}\"" >>  profiles/${DEBIAN_TARGET_DIST}-bpoknl.conf
echo "FORCE_FIRMWARE=1" >>  profiles/${DEBIAN_TARGET_DIST}-bpoknl.conf
echo "extra_udeb_dist=${DEBIAN_TARGET_DIST}-backports" >>  profiles/${DEBIAN_TARGET_DIST}-bpoknl.conf
echo "DI_DIR=/tmp/debian-installer/build/dest/" >>  profiles/${DEBIAN_TARGET_DIST}-bpoknl.conf

# build with firmware then uncomment
#echo "mirror_components=\"main contrib non-free\"" >>  profiles/${DEBIAN_TARGET_DIST}-bpoknl.conf

# contrib firmware
#echo "firmware-b43-installer" >>  profiles/${DEBIAN_TARGET_DIST}-bpoknl.packages
#echo "firmware-b43legacy-installer" >>  profiles/${DEBIAN_TARGET_DIST}-bpoknl.packages
#echo "firmware-microbit-micropython-dl" >>  profiles/${DEBIAN_TARGET_DIST}-bpoknl.packages

# non-free firmware
#echo "firmware-adi" >>  profiles/${DEBIAN_TARGET_DIST}-bpoknl.packages
#echo "firmware-amd-graphics" >>  profiles/${DEBIAN_TARGET_DIST}-bpoknl.packages
#echo "firmware-atheros" >>  profiles/${DEBIAN_TARGET_DIST}-bpoknl.packages
#echo "firmware-bnx2" >>  profiles/${DEBIAN_TARGET_DIST}-bpoknl.packages
#echo "firmware-bnx2x" >>  profiles/${DEBIAN_TARGET_DIST}-bpoknl.packages
#echo "firmware-brcm80211" >>  profiles/${DEBIAN_TARGET_DIST}-bpoknl.packages
#echo "firmware-cavium" >>  profiles/${DEBIAN_TARGET_DIST}-bpoknl.packages
#echo "firmware-intel-sound" >>  profiles/${DEBIAN_TARGET_DIST}-bpoknl.packages
#echo "firmware-intelwimax" >>  profiles/${DEBIAN_TARGET_DIST}-bpoknl.packages
#echo "firmware-ipw2x00" >>  profiles/${DEBIAN_TARGET_DIST}-bpoknl.packages
#echo "firmware-ivtv" >>  profiles/${DEBIAN_TARGET_DIST}-bpoknl.packages
#echo "firmware-iwlwifi" >>  profiles/${DEBIAN_TARGET_DIST}-bpoknl.packages
#echo "firmware-libertas" >>  profiles/${DEBIAN_TARGET_DIST}-bpoknl.packages
#echo "firmware-linux" >>  profiles/${DEBIAN_TARGET_DIST}-bpoknl.packages
#echo "firmware-linux-nonfree" >>  profiles/${DEBIAN_TARGET_DIST}-bpoknl.packages
#echo "firmware-misc-nonfree" >>  profiles/${DEBIAN_TARGET_DIST}-bpoknl.packages
#echo "firmware-myricom" >>  profiles/${DEBIAN_TARGET_DIST}-bpoknl.packages
#echo "firmware-netronome" >>  profiles/${DEBIAN_TARGET_DIST}-bpoknl.packages
#echo "firmware-netxen" >>  profiles/${DEBIAN_TARGET_DIST}-bpoknl.packages
#echo "firmware-qcom-media" >>  profiles/${DEBIAN_TARGET_DIST}-bpoknl.packages
#echo "firmware-qlogic" >>  profiles/${DEBIAN_TARGET_DIST}-bpoknl.packages
#echo "firmware-ralink" >>  profiles/${DEBIAN_TARGET_DIST}-bpoknl.packages
#echo "firmware-realtek" >>  profiles/${DEBIAN_TARGET_DIST}-bpoknl.packages
#echo "firmware-samsung" >>  profiles/${DEBIAN_TARGET_DIST}-bpoknl.packages
#echo "firmware-siano" >>  profiles/${DEBIAN_TARGET_DIST}-bpoknl.packages
#echo "firmware-ti-connectivity" >>  profiles/${DEBIAN_TARGET_DIST}-bpoknl.packages
#echo "firmware-zd1211" >>  profiles/${DEBIAN_TARGET_DIST}-bpoknl.packages

echo "simple-cdd start build"
simple-cdd --profiles ${DEBIAN_TARGET_DIST}-bpoknl --dist ${DEBIAN_TARGET_DIST} --auto-profiles ${DEBIAN_TARGET_DIST}-bpoknl --force-root --verbose --debug
