#!/bin/bash

set -e

function build_cloud_image() {
    local BUILD_DIR="$1"
    DISKS_DIR="$(readlink -f "$BUILD_DIR/disks")"
    INIT_FILES="$(readlink -f "$BUILD_DIR/../cvm_init_config")"
    echo "BUILDING FOCAL CLOUD IMAGE"
    mkdir -p "$DISKS_DIR"
    pushd "$DISKS_DIR"
    wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img

    sudo virt-customize -a focal-server-cloudimg-amd64.img \
        --install nginx --delete /etc/nginx/nginx.conf \
        --copy-in $INIT_FILES/nginx.conf:/etc/nginx --firstboot-command 'nginx'

    qemu-img convert -p -f qcow2 -O raw focal-server-cloudimg-amd64.img focal-server-cloudimg-amd64.raw
    rm focal-server-cloudimg-amd64.img
    popd
}


function build_kernel() {
    local BUILD_DIR="$1"
    KERNELS_DIR="$(readlink -f "$BUILD_DIR/kernels")"
    readonly KERNELS_DIR
    echo "BUILDING CHV LINUX KERNEL"
    mkdir -p "$KERNELS_DIR"
    pushd "$KERNELS_DIR"
    git clone --depth 1 https://github.com/cloud-hypervisor/linux.git -b ch-6.12.8 linux-cloud-hypervisor
    pushd linux-cloud-hypervisor
    make ch_defconfig
    # Do native build of the x86-64 kernel
    KCFLAGS="-Wa,-mx86-used-note=no" make bzImage -j `nproc`
    popd
    cp linux-cloud-hypervisor/arch/x86/boot/bzImage kernel_bin
    rm -rf linux-cloud-hypervisor
    popd
}

function build_stage0() {
    local BUILD_DIR="$1"
    FIRMWARE_DIR="$(readlink -f "$BUILD_DIR/firmware")"
    readonly FIRMWARE_DIR
    echo "BUILDING STAGE0"
    mkdir -p "$FIRMWARE_DIR"
    pushd "$FIRMWARE_DIR"
    git clone https://github.com/project-oak/oak.git
    git clone https://github.com/roy-hopkins/buildigvm.git

    printf "\nBUILDING OAK CONTAINERS STAGE0..."
    pushd oak
    nix develop --command just stage0_bin && \
        rsync ./artifacts/stage0_bin ../stage0_bin
    popd

    pushd buildigvm
    cargo build
    ./target/debug/buildigvm --firmware $FIRMWARE_DIR/stage0_bin --output $FIRMWARE_DIR/stage0.igvm --cpucount 4 sev-snp 
    ./target/debug/buildigvm --firmware $FIRMWARE_DIR/stage0_bin --output $FIRMWARE_DIR/stage0_nosnp.igvm --cpucount 4 native
    popd
    rm -rf oak buildigvm stage0_bin
    popd
}

function build_chv_binary() {
    local BUILD_DIR="$1"
    BINARY_DIR="$(readlink -f "$BUILD_DIR/../../target/release/")"
    echo "BUILDING CHV BINARY"

    cargo build --release
    cp "$BINARY_DIR/cloud-hypervisor" "$BUILD_DIR/"
}

function copy_host_scripts() {
    local BUILD_DIR="$1"
    SCRIPTS="$(readlink -f "$BUILD_DIR/../scripts")"
    echo "COPYING HOST SCRIPTS"

    cp "$SCRIPTS/setup-host.sh" "$BUILD_DIR/"
    cp "$SCRIPTS/run-demo.sh" "$BUILD_DIR/"
}

function create_cloud_init() {
    local BUILD_DIR="$1"
    DISKS_DIR="$(readlink -f "$BUILD_DIR/disks")"
    TEST_DATA="$(readlink -f "$BUILD_DIR/../cloud-init-data/")"
    pushd "$DISKS_DIR"
    rm -f ubuntu-cloudinit.img
    mkdosfs -n CIDATA -C ubuntu-cloudinit.img 8192
    mcopy -oi ubuntu-cloudinit.img -s $TEST_DATA/user-data ::
    mcopy -oi ubuntu-cloudinit.img -s $TEST_DATA/meta-data ::
    mcopy -oi ubuntu-cloudinit.img -s $TEST_DATA/network-config ::
    popd
}
