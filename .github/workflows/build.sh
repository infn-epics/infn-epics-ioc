#!/bin/bash

# A generic build script for epics-containers ioc repositories
#
# Note that this is implemented in bash to make it portable between
# CI frameworks. This approach uses the minimum of GitHub Actions.
# Also works locally for testing outside of CI
#
# INPUTS:
#   PUSH: if true, push the container image to the registry
#   TAG: the tag to use for the container image
#   PLATFORM: the platform to build for (linux/amd64 or linux/arm64)
#   CACHE: the directory to use for caching

export EC_TAG="--tag ${TAG:-latest}"
export EC_PLATFORM="--platform ${PLATFORM:-linux/amd64}"
export EC_CACHE="${CACHE:-/tmp/ec-cache}"
if [[ "${PUSH}" == 'true' ]] ; then EC_PUSH='--push' ; fi

THIS=$(dirname ${0})
set -xe
mkdir -p ${EC_CACHE}

# get the current version of ec CLI
pip install -r ${THIS}/../../requirements_ec.txt

# add cache arguments - local file cache passed by github seems to be most reliable
export EC_CARGS="
    --cache-from type=local,src=${EC_CACHE}
    --cache-to type=local,dest=${EC_CACHE}
"

# add extra cross compilation platforms below if needed  e.g.
#   ec dev build  --arch rtems ... for RTEMS cross compile

# build runtime and developer images
ec -v dev build ${EC_TAG} ${EC_PLATFORM} ${EC_PUSH} ${EC_CARGS}

# extract the ioc schema from the runtime image
ec dev launch-local ${EC_TAG} --execute 'ibek ioc generate-schema' > ibek.ioc.schema.json

# run acceptance tests
shopt -s nullglob # expand to nothing if no tests are found
for t in "${THIS}/../../tests/*.sh"; do ${t}; done

