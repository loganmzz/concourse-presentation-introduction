#!/usr/bin/env bash

rootdir="$(pwd)"
srcdir="${rootdir}/src"
cidir="${rootdir}/ci"

pushd "${srcdir}"
    cargo build
popd
