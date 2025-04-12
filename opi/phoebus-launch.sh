#!/bin/bash

# A launcher for the phoebus to view the generated OPIs

thisdir=$(realpath $(dirname $0))
workspace=$(realpath ${thisdir}/..)

# update settings.ini with CA and PVA ports
cat ${workspace}/opi/settings.ini |
    sed -r \
    -e "s|5064|${EPICS_CA_SERVER_PORT:-5064}|" \
    -e "s|5075|${EPICS_PVA_SERVER_PORT:-5075}|" \
    -e "s|5065|${EPICS_CA_REPEATER_PORT:-5065}|" > /tmp/settings.ini

settings="
-resource ${workspace}/opi/auto-generated/index.bob
-settings /tmp/settings.ini
"

if which phoebus.sh &>/dev/null && [[ -z ${use_container} ]] ; then
    echo "Using phoebus.sh from PATH"
    set -x
    phoebus.sh ${settings} "${@}"

elif module load phoebus 2>/dev/null && [[ -z ${use_container} ]] ; then
    echo "Using phoebus module"
    set -x
    phoebus.sh ${settings} "${@}"

else
    echo "No local phoebus install found, using a container"

    # prefer podman but use docker if USE_DOCKER is set
    if podman version &> /dev/null && [[ -z $USE_DOCKER ]]
        then docker=podman; UIDGID=0:0
        else docker=docker; UIDGID=$(id -u):$(id -g); xhost +SI:localuser:$(id -un)
    fi
    echo "Using $docker as container runtime"


    # settings for container launch
    x11="-e DISPLAY --net host"
    args="--rm -it --security-opt=label=disable --user ${UIDGID}"
    mounts="-v=/tmp:/tmp -v=${workspace}:/workspace -v=${workspace}/..:/workspaces"
    image="ghcr.io/epics-containers/ec-phoebus:latest"

    settings="
    -resource /workspace/opi/auto-generated/index.bob
    -settings /tmp/settings.ini
    "

    set -x
    $docker run ${mounts} ${args} ${x11} ${image} ${settings} "${@}"

fi
