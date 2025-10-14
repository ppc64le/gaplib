#!/bin/bash -e
################################################################################
##  File:  install-dotnetcore-sdk.sh
##  Desc:  Install .NET Core SDK
################################################################################

# Source the helpers for use with the script
# shellcheck disable=SC1091
source "$HELPER_SCRIPTS"/etc-environment.sh
source "$HELPER_SCRIPTS"/install.sh
source "$HELPER_SCRIPTS"/os.sh

dotnet_versions=$(get_toolset_value '.dotnet.versions[]')
dotnet_tools=$(get_toolset_value '.dotnet.tools[].name')

# Disable telemetry
export DOTNET_CLI_TELEMETRY_OPTOUT=1

# Install dotnet dependencies
# https://learn.microsoft.com/en-us/dotnet/core/install/linux-ubuntu-decision#dependencies
update_dnfpkgs
install_dnfpkgs ca-certificates

if [[ "$ARCH" == "ppc64le" || "$ARCH" == "s390x" ]]; then 
    echo "Installing dotnet for architecture: $ARCH"
    install_dnfpkgs dotnet-sdk-8.0
else
    # Install .NET SDKs and Runtimes
    mkdir -p /usr/share/dotnet
    sdks=()
    # shellcheck disable=SC2068
    for version in ${dotnet_versions[@]}; do
        release_url="https://dotnetcli.blob.core.windows.net/dotnet/release-metadata/${version}/releases.json"
        releases=$(cat "$(download_with_retry "$release_url")")
        # shellcheck disable=SC2207
        sdks=("${sdks[@]}" $(echo "${releases}" | jq -r '.releases[].sdk.version | select(contains("preview") or contains("rc") | not)'))
        # shellcheck disable=SC2207
        sdks=("${sdks[@]}" $(echo "${releases}" | jq -r '.releases[].sdks[]?.version | select(contains("preview") or contains("rc") | not)'))
    done
    
    # shellcheck disable=SC2068
    sorted_sdks=$(echo ${sdks[@]} | tr ' ' '\n' | sort -r | uniq -w 5)
    
    ## Download installer from dot.net
    DOTNET_INSTALL_SCRIPT="https://dot.net/v1/dotnet-install.sh"
    install_script_path=$(download_with_retry $DOTNET_INSTALL_SCRIPT)
    chmod +x "$install_script_path"
    
    # shellcheck disable=SC2068
    for sdk in ${sorted_sdks[@]}; do
        echo "Installing .NET SDK $sdk"
        $install_script_path --version "$sdk" --install-dir /usr/share/dotnet --no-path
    done
    ## Dotnet installer doesn't create symlinks to executable or modify PATH
    ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet
fi

set_etc_environment_variable DOTNET_SKIP_FIRST_TIME_EXPERIENCE 1
set_etc_environment_variable DOTNET_NOLOGO 1
set_etc_environment_variable DOTNET_MULTILEVEL_LOOKUP 0
# shellcheck disable=SC2016
prepend_etc_environment_path '$HOME/.dotnet/tools'

# Install .Net tools
# shellcheck disable=SC2068
for dotnet_tool in ${dotnet_tools[@]}; do
    echo "Installing dotnet tool $dotnet_tool"
    dotnet tool install "$dotnet_tool" --tool-path '/etc/skel/.dotnet/tools'
done