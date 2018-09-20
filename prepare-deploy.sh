#!/usr/bin/env bash
set -u -o pipefail

## Settings
DEPLOY_BRANCH="gh-pages"

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DEPLOY="${ROOT}-deploy"
ROOT_WORK="${ROOT}-work"

function fn_cmd_build {
    fn_cmd_clean || return $?

    local gitcommit="$(cd "${ROOT}"; git rev-parse HEAD)"

    echo '   ¤  Prepare deploy directory'
    {
        git worktree add "${ROOT_DEPLOY}" "${DEPLOY_BRANCH}" && \
        rm -rf "${ROOT_DEPLOY}"/*
    } || {
        echo "Unable to prepare deploy directory '${ROOT_DEPLOY}'" >&2
        return 1
    }

    echo '   ¤  Prepare working directory'
    (
        git worktree add --force "${ROOT_WORK}" "${gitcommit}" \
        && git worktree lock --reason "Generating static site" "${ROOT_WORK}"
    ) || {
        echo "Unable to prepare working directory '${ROOT_WORK}'" >&2
        return 1
    }

    echo '   ¤  Build'
    (
        cd "${ROOT_WORK}" \
        && npm ci         \
        && npm run build
    ) || {
        echo "Unable to build slides" >&2
        return 1
    }

    echo '   ¤  Move content'
    (
        cd "${ROOT_WORK}"                                                \
        && fn_copy_into .           assets data js lib plugin index.html \
        && fn_copy_into ./css       print reveal.css                     \
        && fn_copy_into ./css/theme league.css
    ) || {
        echo "Unable to generate deploy content" >&2
        return 1
    }

    echo '   ¤  Commit'
    (
        function fn_publish() {
            git commit -m "Release from ${GIT_COMMIT_ORIGIN}" && git push
        }
        export -f fn_publish
        cd "${ROOT_DEPLOY}" && GIT_COMMIT_ORIGIN="${gitcommit}" bash
    )

    echo "======================================="
    echo "SUCCESSFUL BUILD"
    echo "Visit ${ROOT_DEPLOY}"
    echo "======================================="
}

# Copy resources into a directory, ensuring target directory exist
#
# $2 : Relative base direcotry
# $n : File to copy
function fn_copy_into {
    if [[ $# -eq 0 ]]; then
        echo "Missing base directory" >&2
        return 1
    fi
    local basedir="$1"; shift
    local dst="${ROOT_DEPLOY}/${basedir}"


    echo "... copy ${basedir}"
    
    if [[ $# -eq 0 ]]; then
        echo "Missing files to copy into ${dst}" >&2
        return 1
    fi
    
    if [[ ! -d "${dst}" ]]; then
        mkdir -p "${dst}" \
        || {
            echo "Can't create directory ${dst}" >&2
            return 1
        }
    fi

    while [[ $# -ne 0 ]]; do
        local file="$1"; shift
        local src="${basedir}/${file}"
        cp -r "${src}" "${dst}" \
        || {
            echo "Can't copy from ${src} into ${dst}"
            return 1
        }
    done
}

function fn_cmd_clean {
    echo '   ¤  Clean directory'
    local rc=0
    [[ "$(git worktree list --porcelain | grep -Fx "worktree ${ROOT_WORK}" | wc -l)" == 1 ]] && {
        echo "...unlock worktree"
        git worktree unlock "${ROOT_WORK}" || rc=$?
    }
    echo "...remove working directory"
    rm -rf "${ROOT_WORK}" || rc=$?
    echo "...remove deployment directory"
    rm -rf "${ROOT_DEPLOY}" || rc=$?
    echo "...prune worktree(s)"
    git worktree prune || rc=$?

    [[ "$rc" != 0 ]] && echo "Unable to clean" >&2
    return "${rc}"
}

function fn_main() {
    local rc=0
    local command="${1:-build}"; shift

    case "$command" in
        build|clean)
            "fn_cmd_${command}" "$@"; rc=$?
            ;;
        *)
            echo "Unsupported command $command" >&2
            rc=1
            ;;
    esac

    return $rc
}

fn_main "$@"
