#!/bin/bash

################################################################################
# generic local build script for epics-containers repositories                 #
################################################################################

set -e

# set EPICS_TARGET_ARCH to rtems for RTEMS based targets
T_A=${EPICS_TARGET_ARCH:-linux_x86_64}
# set TARGET to runtime for runtime images
TARGET=${TARGET:-developer}
# set TAG to override the default tag
TAG=${TAG:-ec_test}

if [[ ${T_A} != "linux_x86_64" ]]; then
    # container image extension is the lcase of EPICS_TARGET_ARCH
    IMAGE_EXT=-"${T_A,,}"
fi

cd $(dirname ${0})

# make sure the ioc binaries and config symlink are cleaned up
git clean -fdx ioc

# prefer docker but use podman if USE_PODMAN is set
if docker version &> /dev/null && [[ -z $USE_PODMAN ]]
    then docker=docker
    else docker=podman
fi

# make sure new repos get their submodule ibek-support
if [ ! -d ibek-support/_global ] ; then git submodule update --init ; fi

# build runtime or developer image
set -x
$docker build -t ${TAG} "${@}" --build-arg IMAGE_EXT=$IMAGE_EXT \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    --build-arg EPICS_TARGET_ARCH=$T_A \
    --load --target $TARGET .
