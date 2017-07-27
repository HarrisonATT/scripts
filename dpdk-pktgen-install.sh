#!/bin/bash

################################################################################
#                               Helper Functions                               #
################################################################################
check () {
    # Non-zero error code if command does not exist.
    # "$1" --version &>/dev/null || (echo "	Missing required tool: $1"; return 1)
    apt --installed list 2>/dev/null | tail -n+2 | sed 's_/.*__' | grep "$1" -q
}

################################################################################
#                           Check for required tools                           #
################################################################################
required_tools=( "git" "linux-headers-$(uname -r)" "libpcap-dev" )
missing_tools=()
echo "Checking required tools..."
for tool in "${required_tools[@]}"; do
    check "$tool" || missing_tools+=("${tool}")
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
    echo "Both \$RTE_SDK and \$RTE_TARGET need to be set"
    exit 1
fi

################################################################################
#                                   Download                                   #
################################################################################
set -e

repo="pktgen-dpdk"
url="http://dpdk.org/git/apps/${repo}"
cd
git clone "${url}"
cd "${repo}"
make

echo "pktgen-dpdk successfully installed--hopefully :)

You now have an executable in the app directory. There is a convenience script
located in the tools directory (run.py). However, you will need to alter or copy
the default configuration file (cfg/default.cfg) to use it.

WARNING:
The default.cfg file uses a default black-yellow.theme file. Be aware that if
you are using a terminal with a black background (the default in PuTTY and other
terminal emulators), then you will be unable to see any of the packet
statistics. So you may want to forego the theme and use the default theme.
"
