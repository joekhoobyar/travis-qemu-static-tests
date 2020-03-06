#!/bin/sh
CHROOT_DIR=$HOME/chroots/$ARCH
MIRROR=http://archive.raspbian.org/raspbian
VERSION=buster

rm -rf ${CHROOT_DIR}
# [ -f ${CHROOT_DIR}/.chroot_is_done ] && exit

# Get tools needed for chroot
sudo apt-get update
sudo apt-get install -qq -y binfmt-support sbuild wget debian-archive-keyring ubuntu-keyring gnupg

# Prepare Debian Buster (10) chroot
wget http://http.us.debian.org/debian/pool/main/d/debootstrap/debootstrap_1.0.114_all.deb -O /tmp/debootstrap_1.0.114_all.deb
sudo dpkg --install /tmp/debootstrap_1.0.114_all.deb
sudo mkdir /tmp/arm-chroot
sudo debootstrap --foreign --no-check-gpg --include=fakeroot,build-essential \
  --arch=${CHROOT_ARCH} ${VERSION} ${CHROOT_DIR} ${MIRROR}
sudo chroot ${CHROOT_DIR} ./debootstrap/debootstrap --second-stage
sudo sbuild-createchroot --arch=${CHROOT_ARCH} --foreign --setup-only ${VERSION} ${CHROOT_DIR} ${MIRROR}

# Create file with environment variables which will be used inside chrooted environment
echo "export ARCH=${ARCH}" > envvars.sh
echo "export TRAVIS_BUILD_DIR=${TRAVIS_BUILD_DIR}" >> envvars.sh
chmod a+x envvars.sh

# Install dependencies inside chroot
sudo chroot ${CHROOT_DIR} dpkg --add-architecture ${CHROOT_ARCH}
sudo chroot ${CHROOT_DIR} dpkg --remove-architecture amd64
sudo chroot ${CHROOT_DIR} apt-get update
sudo chroot ${CHROOT_DIR} apt-get --allow-unauthenticated install -qq -y locales
sudo chroot ${CHROOT_DIR} locale
sudo chroot ${CHROOT_DIR} bash -c "echo en_US.UTF-8 UTF-8 > /etc/locale.gen"
sudo chroot ${CHROOT_DIR} locale-gen
sudo chroot ${CHROOT_DIR} apt-get --allow-unauthenticated install -qq -y build-essential git m4 sudo python golang-go

# Create build dir and copy travis build files to our chroot environment
sudo mkdir -p ${CHROOT_DIR}/${TRAVIS_BUILD_DIR}
sudo rsync -av ${TRAVIS_BUILD_DIR}/ ${CHROOT_DIR}/${TRAVIS_BUILD_DIR}/

# Indicate chroot environment has been set up
sudo touch ${CHROOT_DIR}/.chroot_is_done
