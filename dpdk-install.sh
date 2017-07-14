#!/bin/bash

################################################################################
#                               Helper Functions                               #
################################################################################
# Return zero if tool exists, else non-zero.
check () {
    # Non-zero error code if command does not exist.
    "$1" --version &>/dev/null || (echo "	Missing required tool: $1"; return 1)
}

# Return the version number out of a version string
stripver () {
    echo "$1" | grep -Eo '[0-9]+(\.[0-9]+)+' | tail -n1
}

# Return version number of tool
getver () {
    stripver "$($1 --version 2>&1 | head -n1)"
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
required_tools=(make cmp sed grep arch gcc python2 python3)
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
versioned_tools=("gcc 4.9" "python2 2.7" "python3 3.2")
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
#                                    Kernel                                    #
################################################################################
# Check kernel version
kernel_version=2.7
if verlt "$(stripver "$(uname -r)")" "$kernel_version"; then
    echo "Kernel version not at least 2.7."; exit 1
else
    echo "Kernel is up-to-date."
fi


################################################################################
#                                  Huge Pages                                  #
################################################################################
# Huge pages
# http://dpdk.org/doc/guides/linux_gsg/sys_reqs.html#using-hugepages-with-the-dpdk
if grep -q pdpe1gb /proc/cpuinfo; then
    # Check if supports 1GB pages
    huge_page_cmdline="default_hugepagesz=1G hugepagesz=1G hugepages=4"
    huge_page_dir="/mnt/huge_1GB"
    huge_page_fstab="pagesize=1GB"
    echo "Trying to allocate 1GB pages."
    echo "You will need to restart your system for 1GB huge pages to be allocated."
elif grep -q pse /proc/cpuinfo; then
    # Check if supports 2MB pages
    huge_page_cmdline="hugepages=1024"
    huge_page_dir="/mnt/huge"
    huge_page_fstab="defaults"
else
    echo "System does not support huge pages"; exit 1
fi
# Check to see if it's already set up
grep -q 'GRUB_CMDLINE_LINUX=.*huge' /etc/default/grub ||
    sudo sed -i.bak \
         "s/GRUB_CMDLINE_LINUX=\"/GRUB_CMDLINE_LINUX=\"$huge_page_cmdline/" \
         /etc/default/grub ||
    (echo "Cannot set up huge pages in /proc/cpuinfo";
     exit 1)
sudo mkdir -p "$huge_page_dir"
sudo mount -t hugetlbfs nodev "$huge_page_dir"
grep -q "huge" /etc/fstab ||
    echo "nodev ${huge_page_dir} hugetlbfs ${huge_page_fstab} 0 0" | \
        sudo tee -a /etc/fstab &>/dev/null
echo "Completed huge pages setup"


################################################################################
#                                Download File                                 #
################################################################################
# Download DPDK tar file
dpdk_version="17.02.1"
url="http://fast.dpdk.org/rel/dpdk-${dpdk_version}.tar.xz"
file="dpdk-${dpdk_version}.tar.xz"
dir="dpdk-stable-${dpdk_version}"
cd
if [[ ! -f "${file}" && ! -d "${dir}" ]]; then
    echo "wget ${url}"
    wget "${url}"
fi
if [[ -f "${file}" && ! -d "${dir}" ]]; then
    tar xJf "${file}"
fi
if [[ ! -d "${dir}" ]]; then
    echo "Could not download/extract file"
    exit 1
fi
cd "${dir}"


################################################################################
#                                Compile Source                                #
################################################################################
# These environment variables are used by several Makefiles
echo "#!/bin/bash
# These are used for several Makefiles
# http://dpdk.org/doc/guides/linux_gsg/build_sample_apps.html#compiling-a-sample-application
export RTE_SDK=${HOME}/dpdk-stable-${dpdk_version}
export RTE_TARGET=x86_64-native-linuxapp-gcc
" > set-environment-variables && chmod +x set-environment-variables
source set-environment-variables

# This order was created from the suggestion here:
# http://dpdk.org/ml/archives/dev/2016-March/036207.html
# This creates a configuration script
make config T="${RTE_TARGET}"
if yn_defaultn "Do you want to change the config file?"; then
    echo "Edit ${HOME}/dpdk-${dpdk_version}/build/.config"
    echo "Return to line $((LINENO + 2)) in $(basename "$0") to finish installing."
fi
# This compiles something...I'm not sure what
make
# This compiles and installs the dpdk libraries in $dpdk_directory/dpdk-install
make install T="${RTE_TARGET}" DESTDIR="dpdk-install"

# These commands need to be run before any DPDK application is run
echo "#!/bin/bash
# You need to do this before you can run any DPDK application
# http://dpdk.org/doc/guides/linux_gsg/build_dpdk.html#loading-modules-to-enable-userspace-io-for-dpdk
sudo modprobe uio_pci_generic
# sudo modprobe uio
# sudo insmod kmod/igb_uio.ko
sudo modprobe vfio-pci
" > load-modules && chmod +x load-modules

