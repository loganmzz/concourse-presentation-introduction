#!/usr/bin/env bash
set -euo pipefail

echo "   ---   Build project   ---"
pushd source
    cargo build --release
popd
cp source/target/release/concourse-demo-versionning release/demo-$(cat source/version)