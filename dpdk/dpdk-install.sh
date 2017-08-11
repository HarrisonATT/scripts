#!/bin/bash

# This script is intended to install DPDK from scratch. It will check several
# things, including required characteristics of the machine and install required
# packages. It will install the source for DPDK and compile it.

# After using this, there will be two scripts in the DPDK installation
# directory: `load-modules` and `set-environment-variables`. I suggest putting
# `set-environment-variables` in your .bashrc file and running `load-modules`
# once each time you boot.

# This is mostly based on the following pages:
#  - http://dpdk.org/doc/guides/linux_gsg/sys_reqs.html
#  - http://dpdk.org/doc/guides/linux_gsg/build_dpdk.html

# Some things that you may wish to change are listed below:
# dpdk_version (currently 17.02.1)

################################################################################
#                               Helper Functions                               #
################################################################################
# Return zero if tool exists, else non-zero.
checktool () {
    # Non-zero error code if command does not exist.
    "$1" --version &>/dev/null || (echo "	Missing required tool: $1"; return 1)
}

# Return the version number out of a version string
stripver () {
    echo "$1" | grep -Eo '[0-9]+(\.[0-9]+)+' | tail -n1
}

# Return version number of tool
gettoolver () {
    stripver "$($1 --version 2>&1 | head -n1)"
}

# Return zero if a version number is greater than argument, else non-zero.
checkver () {
    # verlt "$(stripver ${2})" "$1"
    verlt "$2" "$(stripver "${1}")"
}

# Return zero if tool has a version number greater than argument, else non-zero.
checktoolver () {
    verlt "$2" "$(gettoolver "$1")" ||
        (echo "	$1 is not at least version $2"; return 1)
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
#                                    Kernel                                    #
################################################################################
echo "Checking kernel version"
kernel_version=2.6.34
if ! checkver "$(uname -r)" "$kernel_version"; then
    echo "Kernel version not at least ${kernel_version}."
    exit 1
fi

echo "Checking glibc version"
glibc_version="2.7"
if ! checkver "$(ldd --version | head -n1)" "$glibc_version"; then
    echo "Glibc version not at least ${glibc_version}."
    exit 1
fi


################################################################################
#                           Check for required tools                           #
################################################################################
echo "Checking required kernel modules..."
required_modules=(sse3)
missing_modules=()
installed_modules=$(grep -m 1 flags /proc/cpuinfo | sed 's/.*://')
for module in "${required_modules[@]}"; do
    grep -q "$module" <(echo "$installed_modules") ||
        missing_modules+=("${module}")
done
if [[ "${#missing_modules[@]}" -eq 0 ]]; then
    cat <<-EOF
			Actually I'm not 100% sure what modules are required, but you definitely
			need at least sse3 extensions (which you have), but I'm guessing avx would
			work too.
			EOF
else
    echo "Missing these modules: ${missing_modules[*]}"
    exit 1
fi

# http://dpdk.org/doc/guides/linux_gsg/sys_reqs.html#compilation-of-the-dpdk

# Check required package and tools
missing_packages=()

echo "Checking required packages..."
required_packages=(xz-utils python-minimal)
installed_packages=$(apt list --installed | sed 's_/.*__')
for package in "${required_packages[@]}"; do
    grep -q "$package" <(echo "$installed_packages") ||
        missing_packages+=("${package}")
done

echo "Checking required tools..."
required_tools=(make cmp sed grep arch gcc python3)
for tool in "${required_tools[@]}"; do
    checktool "$tool" || missing_packages+=("${tool}")
done
if [[ "${#missing_packages[@]}" -eq 0 ]]; then
    echo "Have required packages and tools."
else
    sudo apt-get install "${missing_packages[@]}" || {
        echo "Unable to install missing packages/tools: ${missing_packages[*]}"
        exit 1
    }
fi

# Check tool versions
echo "Checking tools versions..."
versioned_tools=("gcc 4.9" "python2 2.7" "python3 3.2")
for tool_n_version in "${versioned_tools[@]}"; do
    tool="${tool_n_version% *}"
    version="${tool_n_version#* }"
    checktoolver "$tool" "$version" || {
        echo "Some tools are not up-to-date."
        exit 1
    }
done
echo "Tools are up-to-date."

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
sudo update-grub
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
set -e
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
# This compiles DPDK
make
# This installs the dpdk libraries in /usr/local.
# You need sudo because /usr/local is owned by root.
# If you want to install locally, use this command:
# make install T=$RTE_TARGET DESTDIR=<destdir>
sudo make install

# These commands need to be run before any DPDK application is run
cat <<EOF > load-modules && chmod +x load-modules
#!/bin/bash
# You need to do this before you can run any DPDK application
# http://dpdk.org/doc/guides/linux_gsg/build_dpdk.html#loading-modules-to-enable-userspace-io-for-dpdk
sudo modprobe uio_pci_generic
# sudo modprobe uio
# sudo insmod kmod/igb_uio.ko
sudo modprobe vfio-pci
EOF

