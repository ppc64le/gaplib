#!/bin/bash

set -euo pipefail 

header() {
    TS=`date +"%Y-%m-%dT%H:%M:%S%:z"`
    echo "${TS} +--------------------------------------------+"
    echo "${TS} | $*"
    echo "${TS} +--------------------------------------------+"
    echo
}

msg() {
    echo `date +"%Y-%m-%dT%H:%M:%S%:z"` $*
}

patch_runner() {
    header "Cloning repo and Patching runner"
    cd /tmp
    git clone --tags -q "${RUNNERREPO}"
    cd runner
    git checkout $(git tag --sort=-v:refname | grep '^v[0-9]' | head -n1)
    git apply --whitespace=nowarn ${IMAGE_FOLDER}/runner-sdk-8.patch
    sed -i'' -e '/version/s/8......"$/8.0.100"/' src/global.json
}

build_runner() {
    export DOTNET_NUGET_SIGNATURE_VERIFICATION=false
    header "Building runner binary"
    cd src

    msg "Running dev layout"
    ./dev.sh layout Release

    msg "Creating package"
    ./dev.sh package Release

    msg "Running tests"
    ./dev.sh test
}

install_runner() {
    header "Installing runner"
    sudo mkdir -p /opt/runner-cache
    sudo tar -xf /tmp/runner/_package/*.tar.gz -C /opt/runner-cache

    # Create runner user if not exists
    if ! id -u runner >/dev/null 2>&1; then
        sudo useradd -r -m -L -d /home/runner -s /bin/bash runner
    fi

    sudo chown -R runner:runner /opt/runner-cache
    sudo -u runner /opt/runner-cache/config.sh --version
}

pre_cleanup() {
    sudo rm -rf /tmp/runner /opt/runner-cache
}

post_cleanup() {
    sudo rm -rf ${IMAGE_FOLDER}/runner-sdk-8.patch \
           /tmp/preseed-yaml /home/ubuntu/.nuget \
           /home/runner/.local/share
}

run() {
    pre_cleanup
    patch_runner
    build_runner
    install_runner
    post_cleanup
}

RUNNERREPO="https://github.com/actions/runner"

# Parse arguments
while getopts "a:" opt; do
    case ${opt} in
        a) RUNNERREPO=${OPTARG} ;;
        *) exit 1 ;;
    esac
done
shift $(( OPTIND - 1 ))

run 