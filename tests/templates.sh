#!/bin/bash

# test script for ioc-template to verify that the container loads and the
# generic IOC will start - demonstrating that the correct runtime libraries
# all present and correct and that mounting IOC config or ibek config
# works as expected.

TAG=${1} # pass a tag on the command line to test a prebuilt image
FILE=${2} # pass a file to test a specific IOC config
THIS=$(realpath $(dirname $0))
ROOT=$(realpath ${THIS}/..)
CONF=/epics/ioc/config

# log commands and stop on errors
set -ex

# prefer docker but use podman if USE_PODMAN is set
if docker version &> /dev/null && [[ -z $USE_PODMAN ]]
    then docker=docker
    else docker=podman
fi

cd ${ROOT}

# if a tag was passed in this implies it was already built

# try out a test ibek config IOC instance with the generic IOC
opts="--rm --security-opt=label=disable -v ${THIS}:${CONF}"

# Execute jnjrender inside the container before starting the IOC
render_cmd="jnjrender /epics/ibek-templates ${CONF}/templates/${FILE} --output ${CONF}/config.yaml"
start_cmd="/epics/ioc/start.sh"
result=$($docker run ${opts} ${TAG} bash -c "${render_cmd} && ${start_cmd}" 2>&1)

# check that the IOC output expected results
if echo "${result}" | grep -i error; then
    echo "ERROR: errors in IOC startup"
    exit 1
fi

echo "Tests passed!"

