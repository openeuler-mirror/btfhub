#!/usr/bin/env bash

# Validate BTF files in BTFHub Archive. When invoked without arguments, this
# script scans BTF files in BTFHub Archive (specified by $BTFHUB_ARCHIVE_DIR)
# and validate them; when invoked with an argument, this script validates the
# BTF file the argument points to.

set -e
set -o pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/common.sh"

temp_dir=""

scan() {
    if [[ -z "$BTFHUB_ARCHIVE_DIR" ]]; then
        error "missing required BTFHUB_ARCHIVE_DIR"
        exit 1
    fi
    
    info "scanning BTF files under '$BTFHUB_ARCHIVE_DIR'"
    find "$BTFHUB_ARCHIVE_DIR" -type f -name "*.btf.tar.xz" -print0 \
        | xargs -0 -P "$(nproc)" -I BTF_TAR_XZ -- bash -c "'$THIS_SCRIPT' 'BTF_TAR_XZ'"
}

validate() {
    local btf_tar_xz="$1"

    temp_dir="$(mktemp -p "$WORKSPACE_TMP" -d)"

    local btf_filename btf_file
    btf_filename="${btf_tar_xz##*/}"
    btf_filename="${btf_filename%.tar.xz}"
    btf_file="$temp_dir/$btf_filename"

    info "validating '$btf_tar_xz'"

    tar -C "$temp_dir" -xJf "$btf_tar_xz"

    local bpftool_output
    if ! bpftool_output="$(bpftool btf dump file "$btf_file" 2>&1 > /dev/null)"; then
        error "$(printf '%s\n' \
            "$btf_tar_xz: bpftool btf dump failed:" \
            "$bpftool_output")"
        exit 1
    fi

    info "validated '$btf_tar_xz'"
}

main() {
    if [[ -z "$1" ]]; then
        scan
    else
        validate "$1"
    fi
}

cleanup() {
    if [[ -n "$temp_dir" ]]; then
        rm -rf "$temp_dir"
        temp_dir=""
    fi
}

trap cleanup EXIT

main "$@"
