#!/usr/bin/env bash

# Build the builder image.

set -e
set -o pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/common.sh"

main() {
    info "building builder image"

    (set -x; docker version)
    docker build -t openeuler-btfhub-ci-builder - < "$SCRIPT_DIR/Dockerfile"
}

main "$@"
