#!/usr/bin/env bash

set -euo pipefail
basedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

__main() {
    # Provisionned all pipelines
    for pipeline in init version cache develop indus-project; do
        fly -t 'local' sp -p "${pipeline}" -c "${basedir}/dummy-pipeline.yml" -n
        fly -t 'local' up -p "${pipeline}"
        fly -t 'local' sp -p "${pipeline}" -c "${basedir}/empty-pipeline.yml" -n
    done

    # Remove hello
    fly -t 'local' dp -p 'hello' -n

    # Init
    fly -t 'local' sp -p 'init' -c "${basedir}/init-pipeline.yml" -n
    fly -t 'local' tj -w -j 'init/init'
}

__main "$@"
