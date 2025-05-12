ARG IMAGE_EXT

ARG BASE=7.0.8ad3
ARG REGISTRY=ghcr.io/epics-containers
ARG RUNTIME=${REGISTRY}/epics-base${IMAGE_EXT}-runtime:${BASE}
ARG DEVELOPER=${REGISTRY}/epics-base${IMAGE_EXT}-developer:${BASE}

##### build stage ##############################################################
FROM  ${DEVELOPER} AS developer

# The devcontainer mounts the project root to /epics/generic-source
# Using the same location here makes devcontainer/runtime differences transparent.
ENV SOURCE_FOLDER=/epics/generic-source
# connect ioc source folder to its know location
RUN ln -s ${SOURCE_FOLDER}/ioc ${IOC}

# Get the current version of ibek
COPY requirements.txt requirements.txt
RUN pip install --upgrade -r requirements.txt

WORKDIR ${SOURCE_FOLDER}/ibek-support

COPY ibek-support/_ansible _ansible
ENV PATH=$PATH:${SOURCE_FOLDER}/ibek-support/_ansible

COPY ibek-support/iocStats/ iocStats
RUN ansible.sh iocStats

COPY ibek-support/pvlogging/ pvlogging/
RUN ansible.sh pvlogging

COPY ibek-support/autosave/ autosave
RUN ansible.sh autosave

COPY ibek-support/asyn/ asyn/
RUN ansible.sh -v R4-44-2 asyn

COPY ibek-support/busy/ busy/
RUN ansible.sh -v R1-7-3 busy

COPY ibek-support/StreamDevice/ StreamDevice/
RUN ansible.sh -v 2.8.24 StreamDevice

COPY ibek-support/sscan/ sscan/
RUN ansible.sh sscan

COPY ibek-support/calc/ calc/
RUN ansible.sh calc

COPY ibek-support/motor/ motor/
RUN ansible.sh motor

COPY ibek-support/motorMotorSim/ motorMotorSim/
RUN ansible.sh motorMotorSim

COPY ibek-support/ADCore/ ADCore/
RUN ansible.sh ADCore

COPY ibek-support/ADGenICam ADGenICam/
RUN ansible.sh ADGenICam

COPY ibek-support/ADAravis/ ADAravis/
RUN ansible.sh ADAravis

COPY ibek-support/ADSimDetector ADSimDetector/
RUN ansible.sh ADSimDetector

# COPY ibek-support/lakeshore340  lakeshore340/
# RUN  ansible.sh lakeshore340

COPY ibek-support/modbus/ modbus/
RUN ansible.sh modbus

COPY ibek-support/motorNewport motorNewport/
RUN ansible.sh motorNewport

COPY ibek-support/sequencer/ sequencer/
RUN ansible.sh sequencer

# INFN Specific Support
WORKDIR ${SOURCE_FOLDER}/ibek-support-infn

# copy the global ibek files
# TODO remove this once all support is using ansible.sh
COPY ibek-support-infn/_global/ _global

COPY ibek-support-infn/AgilentXgs600 AgilentXgs600
RUN ansible.sh AgilentXgs600

COPY ibek-support-infn/screen-epics-ioc screen-epics-ioc/
RUN ansible.sh screen-epics-ioc

COPY ibek-support-infn/asynInterposeMenlo/ asynInterposeMenlo/
RUN ansible.sh asynInterposeMenlo

COPY ibek-support-infn/epics-nds/ epics-nds/
RUN ansible.sh epics-nds

COPY ibek-support-infn/biltItest biltItest/
RUN ansible.sh biltItest

COPY ibek-support-infn/sigmaPhiStart sigmaPhiStart/
RUN ansible.sh sigmaPhiStart

COPY ibek-support-infn/technosoft/ technosoft/
RUN ansible.sh technosoft

COPY ibek-support-infn/icpdas icpdas
RUN ansible.sh icpdas

COPY ibek-support-infn/easy-driver-epics easy-driver-epics
RUN ansible.sh easy-driver-epics

COPY ibek-support-infn/kima-undulator kima-undulator
RUN ansible.sh kima-undulator

COPY ibek-support-infn/agilent4uhv agilent4uhv
RUN ansible.sh agilent4uhv

COPY ibek-support-infn/agilentipcmini agilentipcmini
#RUN agilentipcmini/install.sh main
RUN ansible.sh agilentipcmini

COPY ibek-support-infn/menloSyncro/ menloSyncro/
RUN ansible.sh menloSyncro

COPY ibek-support-infn/menloLfc/ menloLfc/
RUN ansible.sh menloLfc

COPY ibek-support-infn/menloLac menloLac
RUN ansible.sh menloLac

COPY ibek-support-infn/smc smc
RUN ansible.sh smc

# get the ioc source and build it
COPY ioc/ ${SOURCE_FOLDER}/ioc
RUN ansible.sh ioc

# add some debugging tools for the developer target
RUN ibek support apt-install iputils-ping iproute2 telnet;ibek support add-runtime-packages iputils-ping iproute2 telnet python3-distutils ca-certificates python3.10-venv

# # get the ioc source and build it
# COPY ioc ${SOURCE_FOLDER}/ioc
# RUN ansible.sh ioc
COPY ibek-templates/ /assets/ibek-templates

##### runtime preparation stage ################################################
FROM developer AS runtime_prep

# get the products from the build stage and reduce to runtime assets only
# RUN ibek ioc extract-runtime-assets /assets ${SOURCE_FOLDER}/ibek*
RUN ibek ioc extract-runtime-assets /assets /epics/support/motorTechnosoft/tml_lib/config /epics/support/biltItest /epics/support/agilent4uhv /epics/support/AgilentXgs600 /epics/support/sigmaPhiStart /epics/support/menloSyncro /epics/support/menloLfc /epics/support/menloLac
# RUN ibek ioc extract-runtime-assets /assets
##### runtime stage ############################################################
FROM ${RUNTIME} AS runtime

# get runtime assets from the preparation stage
COPY --from=runtime_prep /assets /

# install runtime system dependencies, collected from install.sh scripts
RUN ibek support apt-install-runtime-packages
RUN cp /epics/support/motorTechnosoft/lib/linux-x86_64/*.so /usr/lib/x86_64-linux-gnu/
RUN chmod 777 -R /epics
CMD ["/bin/bash", "-c", "${IOC}/start.sh"]
