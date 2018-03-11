#!/bin/bash
#
# ev3dev-pbuilder - debian package builder for ev3dev
#
# Copyright (C) 2016 David Lechner <david@lechnology.com>
#

set -e

script_dir=$(dirname $(readlink -f $0))
hook_dir=$script_dir/pbuilder-ev3dev-hooks
host_arch=$(dpkg --print-architecture)

case "$OS" in
debian)
    MIRRORSITE="http://ftp.debian.org/debian"
    COMPONENTS="main"
    OTHERMIRROR="deb http://archive.ev3dev.org/debian $DIST main"
    EV3DEV_KEYRING="ev3dev-archive-keyring"
    ;;
raspbian)
    MIRRORSITE="http://archive.raspbian.org/raspbian"
    COMPONENTS="main"
    OTHERMIRROR="deb http://archive.ev3dev.org/raspbian $DIST main"
    EV3DEV_KEYRING="ev3dev-archive-keyring"
    ;;
ubuntu)
    MIRRORSITE="http://archive.ubuntu.com/ubuntu"
    COMPONENTS="main universe"
    OTHERMIRROR="deb http://ppa.launchpad.net/ev3dev/tools/ubuntu $DIST main"
    EV3DEV_KEYRING="ev3dev-ppa-keyring"
    ;;
*)
    echo "Bad OS"
    exit 1
esac

case "$ARCH" in
amd64)
    if [ "$OS" == "raspbian" ]; then
        echo "Bad ARCH"
        exit 1
    elif [ "$host_arch" != "amd64" ]; then
        echo "Bad ARCH"
        exit 1
    fi
    ;;
i386)
    if [ "$OS" == "raspbian" ]; then
        echo "Bad ARCH"
        exit 1
    elif [ "$host_arch" != "amd64" ] && [ "$host_arch" != "i386" ]; then
        echo "Bad ARCH"
        exit 1
    fi
    ;;
armhf)
    if [ "$OS" == "ubuntu" ]; then
        echo "Bad ARCH"
        exit 1
    elif [ "$host_arch" == "amd64" ] || [ "$host_arch" == "i386" ]; then
        needs_qemu="true"
    elif [ "$host_arch" != "armhf" ]; then
        echo "Bad ARCH"
        exit 1
    fi
    ;;
armel)
    if [ "$OS" == "ubuntu" ]; then
        echo "Bad ARCH"
        exit 1
    elif [ "$host_arch" == "amd64" ] || [ "$host_arch" == "i386" ]; then
        needs_qemu="true"
    elif [ "$host_arch" != "armhf" ] && [ "$host_arch" != "armel" ]; then
        echo "Bad ARCH"
        exit 1
    fi
    ;;
*)
    echo "Bad ARCH"
    exit 1
    ;;
esac

case "$DIST" in
wheezy|jessie|stretch|buster)
    if [ "$OS" != "debian" ] && [ "$OS" != "raspbian" ]; then
        echo "Bad DIST"
        exit 1
    fi
    ;;
trusty|xenial|bionic)
    if [ "$OS" != "ubuntu" ]; then
        echo "Bad DIST"
        exit 1
    fi
    ;;
*)
    echo "Bad DIST"
    exit 1
    ;;
esac

if [ "$TRAVIS" == "true" ]; then
    # on travis, we cache the result between builds, so it needs to be in a
    # separate directory
    BASEDIR="$HOME/cache"
    RESULTDIR="$HOME/result"
else
    BASEDIR="$HOME/pbuilder-ev3dev/$OS"
    RESULTDIR="$HOME/pbuilder-ev3dev/$OS/$DIST-$ARCH"
fi
BASETGZ="$BASEDIR/base-$DIST-$ARCH.tgz"

if [ "$needs_qemu" == "true" ] && [ "$DIST" == "stretch" ]; then
    # stretch version of aptitude crashes qemu.
    # See: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=832710

    # There is no command line option for setting PBUILDERSATISFYDEPENDSCMD,
    # so we have to use a config file.
    stretch_qemu_option="--configfile $script_dir/qemu-stretch.pbuilderrc"
fi

case $1 in

# Create/update a pbuilder base image for the specified OS/DIST/ARCH
base)
    if [ ! -e "$BASETGZ" ]; then
        mkdir -p "$BASEDIR"
        COMMAND="create"
        echo "Creating $BASETGZ"
    else
        COMMAND="update"
        echo "Updating $BASETGZ"
    fi

    if [ "$needs_qemu" == "true" ]; then
        DEBOOTSTRAP="qemu-debootstrap"
    else
        DEBOOTSTRAP="debootstrap"
    fi
    sudo pbuilder --$COMMAND \
        --basetgz "$BASETGZ" \
        --override-config \
        --distribution "$DIST" \
        --architecture "$ARCH" \
        --mirror "$MIRRORSITE" \
        --components "$COMPONENTS" \
        --othermirror "$OTHERMIRROR" \
        --debootstrap "$DEBOOTSTRAP" \
        --hookdir "" \
        --debootstrapopts "--keyring=/usr/share/keyrings/$OS-archive-keyring.gpg" \
        --debootstrapopts "--include=gnupg" \
        --extrapackages "fakeroot ca-certificates man-db debhelper lintian" \
        --keyring "/usr/share/keyrings/$EV3DEV_KEYRING.gpg"
    ;;

build|dev-build)
    mkdir -p "$RESULTDIR"
    if [ "$1" == "dev-build" ]; then
        GBP_OPTIONS="$GBP_OPTIONS --git-ignore-new"
    fi
    BUILDER="pbuilder" \
    PBUILDER_BASE="$BASEDIR" \
    GIT_PBUILDER_OUTPUT_DIR="$RESULTDIR" \
    gbp buildpackage \
        $GBP_OPTIONS \
        --git-pbuilder \
        --git-pbuilder-options="--keyring /usr/share/keyrings/$EV3DEV_KEYRING.gpg --hookdir $hook_dir $stretch_qemu_option $PBUILDER_OPTIONS" \
        --git-dist=$DIST \
        --git-arch=$ARCH
    ;;

dsc-build)
    if [ -z "$2" ]; then
        echo "Must specify .dsc file"
        exit 1
    fi
    if [ ! -f "$2" ]; then
        echo "The file '$2' does not exist"
        exit 1
    fi
    mkdir -p "$RESULTDIR"
    sudo pbuilder --build \
        --basetgz "$BASETGZ" \
        --buildresult "$RESULTDIR" \
        --distribution "$DIST" \
        --architecture "$ARCH" \
        --mirror "$MIRRORSITE" \
        --components "$COMPONENTS" \
        --othermirror "$OTHERMIRROR" \
        --hookdir "$hook_dir" \
        $stretch_qemu_option \
        $PBUILDER_OPTIONS \
        $2
    ;;

*)
    echo "Invalid command."
    exit 1
    ;;

esac
