# CVMs on Cloud Hypervisor

## Overview

This document outlines the steps to set up and run a CVM managed by Cloud Hypervisor.
Note: We can run any Oak Container on CHV using the Oak Container Launcher in this state.

## Prerequisites

- **Build Machine:** A machine capable of generating the demo folder with necessary scripts and the Hats and B&A stacks.
- **Test Machine (SEV-SNP Device):** A machine with a SEV-SNP enabled processor to run the demo in a secure and attested environment.

## Demo Setup

### Prepare the Build Machine Dependencies
On your build machine, Nix following [oak nix setup instructions](https://github.com/project-oak/oak/blob/main/docs/development.md#install-nix).
On your build machine, install libguestfs-tools (needed for virt-customize in next step)

### Run Setup Scripts

```bash
cd kvm_snp_demo
./scripts/build-demo.sh
```

**Scripts Details:**

These scripts perform the following actions:

1.  **Build Kernel:**
    - Builds linux-cloud-hypervisor kernel
    - Copies bzImage artifact to kernel_bin
    - Note: a bzImage of any kernel version that supports virtualization works here (tested 6.5.0 -> 6.12.8)
2.  **Builds Custom Cloud Image:**
    - Downloads current fedora cloud image
    - Uses virt-customize to add nginx package and our add nginx.conf
    - Adds root password so we can login into CVM and add user
    - Note: Cloud init is not currently supported with fw_cfg
3. **Builds Stage0 Firmware:**
    - Builds Oak's Stage0 Firmware
    - Converts firmware to IGVM firmware with buildigvm tool
4. **Builds CHV Binary:**
    - Builds cloud hypervisor binary
    - Copies scripts to setup host and run cloud hypervisor

### Prepare the Test Machine Dependendencies

Transfer the generated `demo` folder from the build machine to the test machine (the SEV-SNP device). You can use `scp` to do copying.

### Setup the Environment on the Test Machine

NOTE: This setup step takes around 10 minutes on a 32 core CPU if trying to compile QEMU.

On the test machine, navigate to the `demo` folder and run the setup script,
which setup the test machine dependencies.

```bash
cd demo
./setup-host.sh
```

**setup-host.sh Details:**

This script performs the following actions:

1.  **Setup Networking:**
    - Creates vrb0 on host network
    - Creates tap device and adds to bridge (TODO: Can add virtual bridge config to add in CHV)
    - Gives cap_net_admin to CHV so that it can connect to tap device
    - Gives us permissions for SEV device

### Launch the CVM

Launches the CVM managed by CHV with an nginx server running at address 198.168.111.12:80

```bash
./run-demo.sh <'snp' if sev-snp mode desired>
```

### Check Confidentiality and Check Connection

Here we log into the CVM using the root credentials we added in custom_cloud_image.sh. We then check
for enablement of SEV-SNP features inside of the guest.
- Log in via ssh with cloud:cloud123
- run 'dmesg | grep SEV'

Then from the host we curl the nginx server running in the CVM to ensure we can reach it.

```bash
curl --verbose http://192.168.111.12:80/index.html
```