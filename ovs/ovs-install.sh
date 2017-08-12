#!/bin/bash

################################################################################
#                               Helper Functions                               #
################################################################################
# Return zero if tool exists, else non-zero.
check () {
    # Non-zero error code if command does not exist.
    "$1" --version &>/dev/null || return 1
}

# Return the version number out of a version string
stripver () {
    # echo "$1" | grep -Eo '[0-9]+(\.[0-9]+)+' | tail -n1
    echo "$1" | grep -Eo '[0-9]+(\.[0-9]+)+' | head -n1
}

# Return version number of tool
getver () {
    stripver "$( ($1 --version 2>&1 || apt list "$1" 2>/dev/null | tail -n+2) | head -n1)"
}

# Return zero if tool has a version number greater than argument, else non-zero.
checkver () {
    verlt "$2" "$(getver "$1")" || (echo "	$1 is not at least version $2"; return 1)
}

# http://stackoverflow.com/a/4024263
verlte() {
    [  "$1" = "$(echo -e "$1\n$2" | sort -V | head -n1)" ]
}
verlt() {
    verlte "$1" "$2" && [ "$1" != "$2" ]
}

# Get a yes or no response
# http://stackoverflow.com/questions/3231804/in-bash-how-to-add-are-you-sure-y-n-to-any-command-or-alias
yn_defaulty () {
    read -r -p "$1 [Y/n] " response
    if [[ "$response" =~ ^([nN][oO]|[nN])+$ ]]; then
        return 1
    else
        return 0
    fi
}
yn_defaultn () {
    read -r -p "$1 [y/N] " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        return 0
    else
        return 1
    fi
}


################################################################################
#                           Check for required tools                           #
################################################################################
# http://dpdk.org/doc/guides/linux_gsg/sys_reqs.html#compilation-of-the-dpdk
required_tools=(autoconf automake libtool)
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

# Check tool versions
versioned_tools=("autoconf 2.63" "automake 1.10")
echo "Checking tools versions..."
for tool_n_version in "${versioned_tools[@]}"; do
    tool="${tool_n_version% *}"
    version="${tool_n_version#* }"
    checkver "$tool" "$version" || {
        echo "Some tools are not up-to-date."
        exit 1
    }
done
echo "Tools are up-to-date."


################################################################################
#                   Check for required environment variables                   #
################################################################################
if [[ -z ${RTE_SDK+x} ]] || [[ -z ${RTE_TARGET+x} ]]; then
    echo "Please set the 'RTE_SDK' and 'RTE_TARGET' environment variables."
    exit 1
fi
export DPDK_BUILD="${RTE_SDK}/${RTE_TARGET}"

################################################################################
#                                   Install                                    #
################################################################################
cd
git clone https://github.com/openvswitch/ovs.git
set -e
cd ovs

# https://github.com/openvswitch/ovs/blob/master/Documentation/intro/install/dpdk.rst
./configure "--with-dpdk=$DPDK_BUILD"
make
echo 'vm.nr_hugepages=2048' | sudo tee /etc/sysctl.d/hugepages.conf
N=4
sudo sysctl -w vm.nr_hugepages="$N"  # where N = No. of 2M huge pages
sudo mount -t hugetlbfs none /dev/hugepages

echo "

I cannot help you any more. You are on your own from here.

Visit this website to figure out the next steps:
https://github.com/openvswitch/ovs/blob/master/Documentation/intro/install/dpdk.rst#user-content-setup-dpdk-devices-using-vfio
"
