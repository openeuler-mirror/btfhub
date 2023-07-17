#!/usr/bin/env bash
# shellcheck disable=SC2034

# Common variables

THIS_SCRIPT="$(realpath "$0")"
COMMON_SCRIPT="$(realpath "${BASH_SOURCE[0]}")"

SCRIPT_DIR="$(dirname "$THIS_SCRIPT")"
SCRIPT_NAME="$(basename "$THIS_SCRIPT")"

WORKSPACE="${WORKSPACE:-/workspace}"
WORKSPACE_TMP="${WORKSPACE_TMP:-/tmp}"

BTFHUB_DIR="$(dirname "$(dirname "$(dirname "$COMMON_SCRIPT")")")"
BTFHUB_ARCHIVE_DIR="${BTFHUB_ARCHIVE_DIR:-$WORKSPACE/btfhub-archive}"

# Utility functions

_log() {
    local level="$1"; shift
    echo >&2 "$SCRIPT_NAME: $level:" "$@"
}

info() {
    _log info "$@"
}

warn() {
    _log warning "$@"
}

error() {
    _log error "$@"
}

if [[ "${#BASH_SOURCE[@]}" == "1" ]]; then
    error "this script should be source'd instead of being directly invoked"
    exit 1
fi
