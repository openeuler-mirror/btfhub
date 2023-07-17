#!/usr/bin/env bash

# Run specified commands in a container bootstrapped with the builder image.

set -e
set -o pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/common.sh"

IN_BUILDER_WORK_DIR="${BTFHUB_IN_BUILDER_WORK_DIR:-/workspace}"

docker_args=(
    docker
    run
    --rm
)

populate_mount_args() {
    docker_args+=(
        -v
        "$WORKSPACE:/workspace"
        -v
        "$WORKSPACE_TMP:/tmp"
    )
}

populate_working_directory_args() {
    docker_args+=(
        -w
        "$IN_BUILDER_WORK_DIR"
    )
}

populate_image_args() {
    docker_args+=(
        openeuler-btfhub-ci-builder
    )
}

populate_command_args() {
    docker_args+=(
        "$@"
    )
}

main() {
    populate_mount_args
    populate_working_directory_args
    populate_image_args

    populate_command_args "$@"

    (set -x; exec "${docker_args[@]}")
}

main "$@"
