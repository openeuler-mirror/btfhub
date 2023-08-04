#!/usr/bin/env bash

# Commit and push changes to the BTFHub Archive repository. The commit message
# can be customized with $BTFHUB_ARCHIVE_COMMIT_MESSAGE. This script requires
# $BTFHUB_ARCHIVE_DIR, $BTFHUB_GIT_USERNAME, $BTFHUB_GIT_PASSWORD to be
# correctly set.

set -e
set -o pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/common.sh"

main() {
    cd "$BTFHUB_ARCHIVE_DIR"

    git add -A
    info "BTFHub Archive repository status:"
    git status

    local commit_message
    if git diff-index --quiet HEAD; then
        info "no changes detected"
    else
        if [[ -n "$BTFHUB_ARCHIVE_COMMIT_MESSAGE" ]]; then
            commit_message="$BTFHUB_ARCHIVE_COMMIT_MESSAGE"
        else
            commit_message="$(printf '%s\n' \
                "Update BTFHub Archive" \
                "" \
                "This commit is created by an automated build process; please refer to" \
                "<$BUILD_URL> for details.")"
        fi
        info "committing changes"
        git commit -m "$commit_message"
        git log -1
    fi

    info "pushing commits to remote"
    # Force push is required because the local branch might have been rebased
    # on origin/master
    git push --force-with-lease
}

main "$@"
