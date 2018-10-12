#!/usr/bin/env bash
set -euo pipefail

rootdir=$(pwd)
version=$(cat ${rootdir}/version/version)

echo "   ---   Install cargo-bump   ---"
ln -s ${rootdir}/cargo-bump/cargo-bump-$(cat cargo-bump/version) /home/rust/.cargo/bin/cargo-bump
chmod +x /home/rust/.cargo/bin/cargo-bump

echo "   ---   Update version   ---"
pushd 'git'
    cargo bump ${version}
popd

echo "   ---   Archive   ---"
echo ${version} > git/version
pushd 'git'
    tar zcvf ${rootdir}/source/demo-${version}-src.tar.gz *
popd