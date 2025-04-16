#!/bin/bash

SNP="$1"

run_demo() {
    if [[ "$1" == "snp" ]]; then
        ./cloud-hypervisor --cpus boot=4 --memory size=8000000K --platform sev_snp=true \
            --net tap=tap1234,ip=192.168.111.12,mac=12:34:56:78:90:ab,mask=255.255.255.0 \
            --vsock cid=3,socket=/tmp/ch.vsock --igvm firmware/stage0.igvm --kernel kernels/kernel_bin \
            --disk path=disks/focal-server-cloudimg-amd64.raw path=disks/ubuntu-cloudinit.img  \
            --cmdline "console=ttyS0 panic=-1 brd.rd_nr=1 brd.rd_size=10485760 brd.max_part=1 \
            ip=192.168.111.12::192.168.111.11:255.255.255.0::enp0s1:off root=/dev/vda1 rw" \
            --serial file=chv-serial.log --log-file ch-fw.log -vvv;
    else 
        ./cloud-hypervisor --cpus boot=4 --memory size=8000000K \
            --net tap=tap1234,ip=192.168.111.12,mac=12:34:56:78:90:ab,mask=255.255.255.0 \
            --vsock cid=3,socket=/tmp/ch.vsock --igvm firmware/stage0_nosnp.igvm --kernel kernels/kernel_bin \
            --disk path=disks/focal-server-cloudimg-amd64.raw path=disks/ubuntu-cloudinit.img  \
            --cmdline "console=ttyS0 panic=-1 brd.rd_nr=1 brd.rd_size=10485760 brd.max_part=1 \
            ip=192.168.111.12::192.168.111.11:255.255.255.0::enp0s1:off root=/dev/vda1 rw" \
            --serial file=chv-serial.log --log-file ch-fw.log -vvv;
    fi 
}

run_demo "$SNP"
