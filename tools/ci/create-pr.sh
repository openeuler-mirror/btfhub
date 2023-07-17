#!/usr/bin/env bash

# Create a PR for BTF updates on Gitee. The API token is provided in
# $BTFHUB_GITEE_API_TOKEN. It is required to provide the path to the local
# BTFHub Archive repository with $BTFHUB_ARCHIVE_DIR. Parameters required to
# create the PR (repository owner and name, base and head branches, title and
# body) can be controlled by environment variables, and will be filled 
# automatically based on the status of the local BTFHub Archive repository if
# not provided.

set -e
set -o pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/common.sh"

GITEE_API_BASE_URL="https://gitee.com/api/v5"

prepare_local_repo() {
    if [[ -z "$BTFHUB_ARCHIVE_DIR" ]]; then
        error "missing required BTFHUB_ARCHIVE_DIR"
        exit 1
    fi
    cd "$BTFHUB_ARCHIVE_DIR"
    info "using local BTFHub Archive repository at $(pwd)"
}

prepare_api_token() {
    if [[ -z "$BTFHUB_GITEE_API_TOKEN" ]]; then
        error "missing required BTFHUB_GITEE_API_TOKEN"
        exit 1
    fi
    info "using BTFHUB_GITEE_API_TOKEN: $BTFHUB_GITEE_API_TOKEN"
}

prepare_repo_owner_name() {
    if [[ -z "$BTFHUB_ARCHIVE_REPO" ]]; then
        BTFHUB_ARCHIVE_REPO="$(git remote get-url origin \
            | sed 's/^https:\/\/gitee.com\///' \
            | sed 's/^git@gitee.com://' \
            | sed 's/.git$//')"
    fi
    info "using BTFHUB_ARCHIVE_REPO: $BTFHUB_ARCHIVE_REPO"
}

prepare_pr_head() {
    if [[ -z "$BTFHUB_ARCHIVE_PR_HEAD" ]]; then
        BTFHUB_ARCHIVE_PR_HEAD="$(git branch --show-current)"
    fi
    info "using BTFHUB_ARCHIVE_PR_HEAD: $BTFHUB_ARCHIVE_PR_HEAD"
}

prepare_pr_base() {
    if [[ -z "$BTFHUB_ARCHIVE_PR_BASE" ]]; then
        BTFHUB_ARCHIVE_PR_BASE=master
    fi
    info "using BTFHUB_ARCHIVE_PR_BASE: $BTFHUB_ARCHIVE_PR_BASE"
}

prepare_pr_title() {
    if [[ -z "$BTFHUB_ARCHIVE_PR_TITLE" ]]; then
        BTFHUB_ARCHIVE_PR_TITLE="Update BTF files"
    fi
    info "using BTFHUB_ARCHIVE_PR_TITLE: $BTFHUB_ARCHIVE_PR_TITLE"
}

prepare_pr_body() {
    if [[ -z "$BTFHUB_ARCHIVE_PR_BODY" ]]; then
        BTFHUB_ARCHIVE_PR_BODY="$(printf '%s\n' \
            'This PR updates BTF files in this repository.' \
            '' \
            "Commits and changes included in this PR are created by an automated CI pipeline; visit [**$JOB_NAME**]($JOB_URL) for details.")"
    fi
    info "$(printf 'using BTFHUB_ARCHIVE_PR_BODY: %q' "$BTFHUB_ARCHIVE_PR_BODY")"
}

check_branches() {
    if git rev-parse --is-inside-work-tree > /dev/null 2>&1 && \
        [[ "$(git rev-list --count "origin/$BTFHUB_ARCHIVE_PR_BASE..origin/$BTFHUB_ARCHIVE_PR_HEAD")" == "0" ]]; then
        info "no need to create PR: the base branch $BTFHUB_ARCHIVE_PR_BASE is already up-to-date with the head branch $BTFHUB_ARCHIVE_PR_HEAD"
        exit 0
    fi
}

check_existing_pr() {
    local existing_pr_url
    existing_pr_url="$(printf '%s/repos/%s/pulls?state=open&head=%s&base=%s' \
        "$GITEE_API_BASE_URL" \
        "$BTFHUB_ARCHIVE_REPO" \
        "$BTFHUB_ARCHIVE_PR_HEAD" \
        "$BTFHUB_ARCHIVE_PR_BASE" \
        | xargs curl -sS --fail-with-body \
        | jq -r '.[].html_url')"
    if [[ -n "$existing_pr_url" ]]; then
        info "no need to create PR: PR already exists and is still open: $existing_pr_url"
        exit 0
    fi
}

do_create_pr() {
    local create_pr_request create_pr_response
    create_pr_request="$(echo '{}' \
        | jq -c ".access_token = \"$BTFHUB_GITEE_API_TOKEN\"" \
        | jq -c ".head = \"$BTFHUB_ARCHIVE_PR_HEAD\"" \
        | jq -c ".base = \"$BTFHUB_ARCHIVE_PR_BASE\"" \
        | jq -c ".title = \"$BTFHUB_ARCHIVE_PR_TITLE\"" \
        | jq -c ".body = \"$BTFHUB_ARCHIVE_PR_BODY\"")"
    if ! create_pr_response="$(curl -sS --fail-with-body -X POST -d "$create_pr_request" \
        -H 'Content-Type: application/json;charset=UTF-8' \
        -H 'Accept: application/json;charset=UTF-8' \
        "$GITEE_API_BASE_URL/repos/$BTFHUB_ARCHIVE_REPO/pulls")"; then
        error "failed to create PR: $(echo "$create_pr_response" | jq -r .message)"
        exit 1
    fi
    info "successfully created PR: $(echo "$create_pr_response" | jq -r '.html_url')"
}

prepare_variables() {
    info "preparing variables"

    prepare_local_repo
    prepare_api_token
    prepare_repo_owner_name
    prepare_pr_head
    prepare_pr_base
    prepare_pr_title
    prepare_pr_body
}

create_pr() {
    info "creating PR"

    check_branches
    check_existing_pr

    do_create_pr
}

main() {
    prepare_variables
    create_pr
}

main "$@"
