#!/bin/bash

# test script for ioc-template to verify that the container loads and the
# generic IOC will start - demonstrating that the correct runtime libraries
# all present and correct and that mounting IOC config or ibek config
# works as expected.

THIS_DIR=$(realpath $(dirname $0))
ROOT=$(realpath ${THIS_DIR}/..)

set -ex

cd ${ROOT}
# Build the container (inherit arguments from CI workflow if set) ##############
ec dev build ${EC_TAG}

# try out an ibek config IOC instance with the generic IOC #####################
ec dev launch-local tests/example-config --args '-dit' ${EC_TAG}
ec dev wait-pv EXAMPLE2:A --attempts 20
ec dev exec 'caput EXAMPLE2:A 1.3'
ec dev exec 'caput EXAMPLE2:B 1.2'
ec dev exec 'caget EXAMPLE2:SUM' | grep '2.5'

# Test an ibek IOC #############################################################
ec dev launch-local tests/example-ibek-config --args '-dit' ${EC_TAG}
ec dev wait-pv EXAMPLE:IBEK:A --attempts 20
ec dev exec 'caput EXAMPLE:IBEK:A 1.3'
ec dev exec 'caput EXAMPLE:IBEK:B 1.2'
ec dev exec 'caget EXAMPLE:IBEK:SUM' | grep '2.5'
ec dev exec 'caget test-ibek-ioc:EPICS_VERS' | grep 'R7.0.7'

# Stop the test IOC ############################################################
ec dev stop

# Done #########################################################################
echo
echo "All tests passed!"



