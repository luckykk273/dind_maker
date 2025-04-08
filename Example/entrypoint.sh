#!/bin/bash

# Clone the code repository recursively.
git clone --recurse-submodules https://github.com/sonic-net/sonic-buildimage.git

# Ensure the 'overlay' module is loaded on your development system
sudo modprobe overlay

# (Optional) Checkout a specific branch. By default, it uses master branch.
# For example, to checkout the branch 201911, use "git checkout 201911"
# git checkout [branch_name]

# Modify cache directory to prevent from permission denied error
sed -i 's|^SONIC_DPKG_CACHE_SOURCE ?= /var/cache/sonic/artifacts$|SONIC_DPKG_CACHE_SOURCE ?= $(shell pwd)/cache/sonic/artifacts|' "rules/config"

# Execute make init once after cloning the repo,
# or after fetching remote repo with submodule updates
make init

# Execute make configure once to configure ASIC
make configure PLATFORM=broadcom

# Build SONiC image with 4 jobs in parallel.
# Note: You can set this higher, but 4 is a good number for most cases
#       and is well-tested.
make SONIC_BUILD_JOBS=4 target/sonic-broadcom.bin

if [ -t 1 ]; then
    # Run the provided command in interactive mode
    exec "$@"
fi

# Below will keep the detached daemon alive even the command is finished.
# if [ -t 1 ]; then
#     exec "$@"
# else
#     # Detached mode; keep the container alive even the command is finished.
#     tail -f /dev/null
# fi