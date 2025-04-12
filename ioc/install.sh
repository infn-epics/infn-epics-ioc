#!/bin/bash

# global install script for all support modules to reference
# every install.sh script in ibek-support should call this script
# before it compiles its support module.

THIS=$(realpath $(dirname $0))

x86_cfg="${THIS}/configure/CONFIG_SITE.Common.linux-x86_64"

# for RTEMS builds don't build for the host architecture, target only
if [[ $EPICS_TARGET_ARCH == "RTEMS"* ]]; then
    touch ${x86_cfg}
    sed -i '/VALID_BUILDS/d' ${x86_cfg}
    echo "VALID_BUILDS=Host" >> ${x86_cfg}
fi


