#!/usr/bin/env bash
rootdir=$(pwd)

[[ ! -d "${rootdir}/repository.in" || ! -d "${rootdir}/repository.out" ]] || cp -r "${rootdir}/repository.in"/* "${rootdir}/repository.out/"

if [[ -d "${rootdir}/repository.out" ]]; then
    export M2_LOCAL_REPOSITORY=${rootdir}/repository.out
elif [[ -d "${rootdir}/repository.in" ]]; then
    export M2_LOCAL_REPOSITORY=${rootdir}/repository.in
else
    export M2_LOCAL_REPOSITORY=${HOME}/.m2/repository
fi

pushd "src"
    mvn -s "${rootdir}/src/src/ci/assets/settings.xml" clean compile
popd
