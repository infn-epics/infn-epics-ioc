#!/bin/bash

# global install script for support all support modules to reference

x86_cfg='./configure/CONFIG_SITE.Common.linux-x86_64'

# for RTEMS builds don't build for the host architecture, target only
if [[ $TARGET_ARCHITECTURE == "rtems" ]]; then
    touch ${x86_cfg}
    sed -i '/VALID_BUILDS/d' ${x86_cfg}
    echo "VALID_BUILDS=Host" >> ${x86_cfg}
fi
