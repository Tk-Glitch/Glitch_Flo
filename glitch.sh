#!/bin/bash

# Glitch kernel build-script
#
# clean : clean the build directory.

# CM repo path :
repo=~/android/system

# Choose Android version :
#init="4.1"
#init="4.2"
init="4.3"

# Type of build (aroma or zImage)
export build_type=""

export CM_REPO=$repo

# Toolchain :
export ARCH="arm"
#export CROSS_PREFIX="$repo/prebuilts/gcc/linux-x86/arm/arm-eabi-4.6/bin/arm-eabi-"
export CROSS_PREFIX="$repo/prebuilts/gcc/linux-x86/arm/sabermod-androideabi-4.8/bin/arm-linux-androideabi-"

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
            CROSS_PREFIX="$repo/prebuilts/gcc/darwin-x86/arm/arm-eabi-4.8/bin/arm-eabi-"
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


if [ "$build_type" = "aroma" ] ; then
mkdir -p $KERNEL_DIR/release/aroma/system/lib/modules/
else
mkdir -p $KERNEL_DIR/release/zimage/system/lib/modules/
fi

cd $target_dir

if [ "$build_type" = "aroma" ] ; then
find -name '*.ko' -exec cp -av {} $KERNEL_DIR/release/aroma/system/lib/modules/ \;
"$CROSS_PREFIX"strip --strip-unneeded $KERNEL_DIR/release/aroma/system/lib/modules/*
else
find -name '*.ko' -exec cp -av {} $KERNEL_DIR/release/zimage/system/lib/modules/ \;
"$CROSS_PREFIX"strip --strip-unneeded $KERNEL_DIR/release/zimage/system/lib/modules/*
fi

cd $KERNEL_DIR

if [ "$build_type" = "aroma" ] ; then
mv $target_dir/arch/arm/boot/zImage $KERNEL_DIR/release/aroma/boot/glitch.zImage
else
mv $target_dir/arch/arm/boot/zImage $KERNEL_DIR/release/zimage/kernel/zImage
fi

echo "packaging it up"

if [ "$build_type" = "aroma" ] ; then
cd release/aroma
else
cd release/zimage
fi

mkdir -p $KERNEL_DIR/release/Flashable-flo-CMfriendly

REL=Glitch-flo-$(date +%Y%m%d-r%H).zip
	
	if [ "$build_type" = "aroma" ] ; then
	zip -q -r ${REL} boot config META-INF system
	else
	zip -q -r ${REL} kernel META-INF system
	fi

	#sha256sum ${REL} > ${REL}.sha256sum
	mv ${REL}* $KERNEL_DIR/release/Flashable-flo-CMfriendly/

if [ "$build_type" = "aroma" ] ; then
rm boot/glitch.zImage
else
rm kernel/zImage
fi

rm -r system/lib/modules/*

cd $KERNEL_DIR

echo ""
echo ${REL}
}
    
setup

if [ "$1" = clean ] ; then
    rm -fr "$BUILD_DIR"/*
    cd release
    rm `find ./ -name '*.*~'` -rf
    rm `find ./ -name '*~'` -rf
    cd $KERNEL_DIR
    echo ""
    echo "Old build cleaned"

else

if [ "$1" = kclean ] ; then
    rm -fr "$KERNEL_DIR"/release/Flashable-flo-CMfriendly/*
    echo "Built kernels cleaned"

else

time {

    build flo

}
fi
fi
