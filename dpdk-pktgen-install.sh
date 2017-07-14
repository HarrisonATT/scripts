#!/bin/bash

################################################################################
#                               Helper Functions                               #
################################################################################
check () {
    # Non-zero error code if command does not exist.
    "$1" --version &>/dev/null || (echo "	Missing required tool: $1"; return 1)
}

################################################################################
#                           Check for required tools                           #
################################################################################
required_tools=(git linux-headers-3.5.0-32-generic libpcap-dev)
missing_tools=()
echo "Checking required tools..."
for tool in "${required_tools[@]}"; do
    check "$tool" || missing_tools+="${tool}"
done
if [[ "${#missing_tools[@]}" -eq 0 ]]; then
    echo "Have required tools."
else
    sudo apt-get install "${missing_tools[@]}" || {
        echo "Unable to install missing tools: ${missing_tools[*]}"
        exit 1
    }
fi

################################################################################
#                   Check for required environment variables                   #
################################################################################
if [[ -z "${RTE_SDK}" ]] || [[ -z "${RTE_TARGET}" ]]; then
    echo 'Both $RTE_SDK and $RTE_TARGET need to be set'
    exit 1
fi

################################################################################
#                                   Download                                   #
################################################################################
set -e

repo="pktgen-dpdk"
url="http://dpdk.org/git/apps/${repo}"
cd
echo "tmp"; exit 1
git clone "${url}"
cd "${repo}"
make
