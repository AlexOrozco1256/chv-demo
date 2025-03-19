#!/bin/bash

set -e

SCRIPTS_DIR="$(dirname "$0")"
readonly SCRIPTS_DIR
DEMO_DIR="$(readlink -f "$SCRIPTS_DIR/../demo")"
readonly DEMO_DIR
cd "$SCRIPTS_DIR"
mkdir -p "$DEMO_DIR"

# shellcheck disable=1091
source ./build-lib.sh

sudo ls

build_cloud_image "$DEMO_DIR"
build_kernel "$DEMO_DIR"
build_stage0 "$DEMO_DIR"
build_chv_binary "$DEMO_DIR"
copy_host_scripts "$DEMO_DIR"
create_cloud_init "$DEMO_DIR"