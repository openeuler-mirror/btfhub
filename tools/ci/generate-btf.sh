#!/usr/bin/env bash

# Build the btfhub tool and generate BTF files. Command-line args are passed
# to the btfhub tool.

set -e
set -o pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/common.sh"

main() {
    cd "$BTFHUB_DIR"

    info "fetching existing BTF files"
    make BTFHUB_ARCHIVE_DIR="$BTFHUB_ARCHIVE_DIR" bring

    info "building btfhub tool"
    make

    info "generating BTF files"
    ./btfhub "$@"

    info "copying built BTF files to local BTFHub Archive"
    make BTFHUB_ARCHIVE_DIR="$BTFHUB_ARCHIVE_DIR" take
}

main "$@"
