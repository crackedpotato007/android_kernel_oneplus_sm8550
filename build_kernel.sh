#!/bin/bash

echo -e "\n[INFO]: BUILD STARTED..!\n"

# Init submodules
git submodule init && git submodule update

export KERNEL_ROOT="$(pwd)"
export ARCH=arm64
export KBUILD_BUILD_USER="@reaperlord10"

# Install build dependencies if first run
if [ ! -f ".requirements" ]; then
    echo -e "\n[INFO] Installing build dependencies (Arch Linux)\n"
    sudo pacman -Syu --needed --noconfirm \
        git base-devel \
        device-tree-compiler lz4 xz zlib \
        jdk17-openjdk \
        clang llvm lld \
        python p7zip android-tools erofs-utils \
        gnupg flex bison gperf \
        zip curl ncurses \
        libx11 readline mesa \
        bc grep tofrodos python-markdown \
        libxml2 libxslt make repo cpio kmod \
        openssl libelf pahole \
        libarchive zstd
    touch .requirements
fi

# Create necessary directories
mkdir -p "${KERNEL_ROOT}/out" "${KERNEL_ROOT}/build"

# Export toolchain paths (system Clang and LLVM)
export PATH="/usr/bin:${PATH}"
export LD_LIBRARY_PATH="/usr/lib:${LD_LIBRARY_PATH}"

# Cross-compile environment variables (use Arch ARM toolchains)
if ! pacman -Qi aarch64-linux-gnu-gcc &>/dev/null; then
    echo -e "\n[INFO] Installing ARM GCC Cross-Compiler\n"
    sudo pacman -S --needed aarch64-linux-gnu-gcc
fi

export BUILD_CROSS_COMPILE="aarch64-linux-gnu-"
export BUILD_CC="/usr/bin/clang"

# Build options for the kernel
export BUILD_OPTIONS="
-C ${KERNEL_ROOT} \
O=${KERNEL_ROOT}/out \
-j$(nproc) \
ARCH=arm64 \
LLVM=1 \
LLVM_IAS=1 \
CROSS_COMPILE=${BUILD_CROSS_COMPILE} \
CC=${BUILD_CC} \
CLANG_TRIPLE=aarch64-linux-gnu- \
"

build_kernel(){
    # Make default configuration
    make ${BUILD_OPTIONS} gki_defconfig
    make ${BUILD_OPTIONS} vendor/kalama_GKI.config
    make ${BUILD_OPTIONS} vendor/oplus/crow_GKI.config
    make ${BUILD_OPTIONS} vendor/debugfs.config
    make ${BUILD_OPTIONS} vendor/ksu_susfs.config

    # Optional GUI config
    make ${BUILD_OPTIONS} menuconfig

    # Build the kernel Image
    make ${BUILD_OPTIONS} Image || exit 1

    # Copy the built kernel to build directory
    cp "${KERNEL_ROOT}/out/arch/arm64/boot/Image" "${KERNEL_ROOT}/build"

    echo -e "\n[INFO]: BUILD FINISHED..!"
}
build_kernel