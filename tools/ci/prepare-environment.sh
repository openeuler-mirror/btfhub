#!/usr/bin/env bash

# Prepare build environment. This script requires $WORKSPACE, $WORKSPACE_TMP,
# $BTFHUB_ARCHIVE_DIR, $BTFHUB_GIT_AUTHOR_NAME, $BTFHUB_ARCHIVE_AUTHOR_EMAIL
# to be set correctly.

set -e
set -o pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/common.sh"

configure_repo() {
    info "configuring BTFHub and BTFHub Archive repositories"

    pushd "$BTFHUB_DIR"
    info "fixing permissions for BTFHub repository"
    chown -R "$(id -u):$(id -g)" .

    info "configuring author info for BTFHub repository"
    git config --local user.name "$BTFHUB_GIT_AUTHOR_NAME"
    git config --local user.email "$BTFHUB_GIT_AUTHOR_EMAIL"
    popd

    pushd "$BTFHUB_ARCHIVE_DIR"
    info "fixing permissions for BTFHub Archive repository"
    chown -R "$(id -u):$(id -g)" .

    info "configuring author info for BTFHub Archive repository"
    git config --local user.name "$BTFHUB_GIT_AUTHOR_NAME"
    git config --local user.email "$BTFHUB_GIT_AUTHOR_EMAIL"

    info "configuring tracking branch for BTFHub Archive repository"
    git branch --set-upstream-to "origin/$(git branch --show-current)"

    info "rebasing master branch"
    git rebase origin/master
    popd
}

inspect_environment() {
    info "inspecting build environment"

    (set -x; {
        uname -a
        bpftool --version
        clang --version
        find --version
        git --version
        go version
        jq --version
        make --version
        pahole --version
        rsync --version
        xargs --version
        xz --version
    })
}

fix_permissions() {
    info "fixing permissions"

    local uid gid
    uid="$(id -u)"
    gid="$(id -g)"

    chown -R "$uid:$gid" "$WORKSPACE"
    chown -R "$uid:$gid" "$WORKSPACE_TMP"
}

main() {
    inspect_environment
    configure_repo
}

main "$@"
