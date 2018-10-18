#!/usr/bin/env bash

set -euo pipefail
basedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
concourse_manager=~/.local/share/concourse/manage.sh

__main() {
    __init_pipelines
    __init_s3
}


__init_pipelines() {
    echo '   ===    INIT PIPELINES   ==='

    echo '   ---    Provisionned all pipelines   ---'
    for pipeline in init version cache develop indus-project; do
        fly -t 'local' sp -p "${pipeline}" -c "${basedir}/dummy-pipeline.yml" -n
        fly -t 'local' up -p "${pipeline}"
        fly -t 'local' sp -p "${pipeline}" -c "${basedir}/empty-pipeline.yml" -n
    done

    echo '   ---    Remove hello   ---'
    fly -t 'local' dp -p 'hello' -n

    echo '   ---   Init worker   ---'
    fly -t 'local' sp -p 'init' -c "${basedir}/init-pipeline.yml" -n
    fly -t 'local' tj -w -j 'init/init'
}

__init_s3() {
    echo '   ===   INIT S3   ==='
    echo '   ---   Init hello/recipient   ---'
    "${concourse_manager}" s3 pipe 'hello/recipient-1.0.0.txt' <<<'World'

    echo '   ---   Removes version/**   ---'
    "${concourse_manager}" s3 rm --recursive --force 'version/'
}

__main "$@"
