#!/bin/bash

# CM10 repo path :
repo=~/android/system

# Choose Android 4.1.x or 4.2.x initrd :
#init="4.1"
init="4.3"

# Glitch kernel build-script parameters :
#
# "device" : build for a supported device (Flo).
# You can list all devices you want to build, separated by a space.
#
# clean : clean the build directory.

export CM_REPO=$repo

# Toolchain :
export ARCH="arm"

#export CROSS_PREFIX="$repo/prebuilts/gcc/linux-x86/arm/arm-eabi-4.8-linaro/bin/arm-eabi-"
#export CROSS_PREFIX="$repo/prebuilts/gcc/linux-x86/arm/arm-eabi-4.6/bin/arm-eabi-"
export CROSS_PREFIX="$repo/prebuilts/gcc/linux-x86/arm/sabermod-androideabi-4.8/bin/arm-linux-androideabi-"
#export CROSS_PREFIX="$repo/prebuilts/gcc/linux-x86/arm/linaro_4.8.2-2013.09/bin/arm-gnueabi-"


setup ()
{

    if [ x = "x$CM_REPO" ] ; then
        echo "Android build environment must be configured"
        exit 1
    fi
    . "$CM_REPO"/build/envsetup.sh

#   Arch-dependent definitions
    case `uname -s` in
        Darwin)
            KERNEL_DIR="$(dirname "$(greadlink -f "$0")")"
            CROSS_PREFIX="$repo/prebuilts/gcc/darwin-x86/arm/arm-eabi-4.6/bin/arm-eabi-"
            ;;
        *)
            KERNEL_DIR="$(dirname "$(readlink -f "$0")")"
            CROSS_PREFIX="$CROSS_PREFIX"
            ;;
    esac

    BUILD_DIR="../glitch-build/kernel"

    if [ x = "x$NO_CCACHE" ] && ccache -V &>/dev/null ; then
        CCACHE=ccache
        CCACHE_BASEDIR="$KERNEL_DIR"
        CCACHE_COMPRESS=1
        CCACHE_DIR="$CM_REPO/kernel/Asus/.ccache"
        export CCACHE_DIR CCACHE_COMPRESS CCACHE_BASEDIR
    else
        CCACHE=""
    fi

}

build ()
{

    local target=flo
    echo "Building for flo - Android $init.x"
    local target_dir="$BUILD_DIR/flo"
    local module
    rm -fr "$target_dir"
    mkdir -p "$target_dir"

    mka -C "$KERNEL_DIR" O="$target_dir" cyanogen_flo_defconfig HOSTCC="$CCACHE gcc"
    mka -C "$KERNEL_DIR" O="$target_dir" HOSTCC="$CCACHE gcc" CROSS_COMPILE="$CCACHE $CROSS_PREFIX" zImage modules

[[ -d release ]] || {
	echo "must be in kernel root dir"
	exit 1;
}

echo "copying modules and zImage"

mkdir -p $KERNEL_DIR/release/zimage/system/lib/modules/

cd $target_dir

find -name '*.ko' -exec cp -av {} $KERNEL_DIR/release/zimage/system/lib/modules/ \;
"$CROSS_PREFIX"strip --strip-unneeded $KERNEL_DIR/release/zimage/system/lib/modules/*

cd $KERNEL_DIR

mv $target_dir/arch/arm/boot/zImage $KERNEL_DIR/release/zimage/kernel/zImage

echo "packaging it up"

cd release/zimage && {

mkdir -p $KERNEL_DIR/release/Flashable-flo-CMfriendly

REL=CM10.2-flo-Glitch-$(date +%Y%m%d.%H%M).zip
	
	zip -q -r ${REL} kernel META-INF system
	#sha256sum ${REL} > ${REL}.sha256sum
	mv ${REL}* $KERNEL_DIR/release/Flashable-flo-CMfriendly/

rm kernel/zImage
rm -r system/lib/modules/*
}

cd $KERNEL_DIR

echo ${REL}
}
    
setup

if [ "$1" = clean ] ; then
    rm -fr "$BUILD_DIR"/*
    echo "Old build cleaned"

else

time {

    build flo

}
fi
