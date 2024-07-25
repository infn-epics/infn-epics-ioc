##### build stage ##############################################################

ARG TARGET_ARCHITECTURE
ARG BASE=7.0.8ec1b3
ARG REGISTRY=ghcr.io/epics-containers

FROM  ${REGISTRY}/epics-base-${TARGET_ARCHITECTURE}-developer:${BASE} AS developer


# The devcontainer mounts the project root to /epics/generic-source
# Using the same location here makes devcontainer/runtime differences transparent.
ENV SOURCE_FOLDER=/epics/generic-source
# connect ioc source folder to its know location
RUN ln -s ${SOURCE_FOLDER}/ioc ${IOC}

# Get latest ibek while in development. Will come from epics-base when stable
COPY requirements.txt requirements.txt
RUN pip install --upgrade -r requirements.txt

WORKDIR ${SOURCE_FOLDER}/ibek-support

# copy the global ibek files
COPY ibek-support/_global/ _global

COPY ibek-support/iocStats/ iocStats
RUN iocStats/install.sh 3.2.0

################################################################################
#  TODO - Add further support module installations here
################################################################################

COPY ibek-support/asyn/ asyn/
RUN asyn/install.sh R4-44

COPY ibek-support/autosave/ autosave/
RUN autosave/install.sh R5-11

COPY ibek-support/busy/ busy/
RUN busy/install.sh R1-7-3

COPY ibek-support/StreamDevice/ StreamDevice/
RUN StreamDevice/install.sh 2.8.24

COPY ibek-support/sscan/ sscan/
RUN sscan/install.sh R2-11-6

COPY ibek-support/calc/ calc/
RUN calc/install.sh R3-7-5

COPY ibek-support/motor/ motor/
RUN motor/install.sh R7-3

COPY ibek-support/motorMotorSim/ motorMotorSim/
RUN motorMotorSim/install.sh R1-2

COPY ibek-support/ADCore/ ADCore/
RUN ADCore/install.sh R3-13

COPY ibek-support/ADGenICam ADGenICam/
RUN ADGenICam/install.sh master

COPY ibek-support/ADAravis/ ADAravis/
RUN ADAravis/install.sh R2-3

COPY ibek-support/ADSimDetector ADSimDetector/
RUN ADSimDetector/install.sh R2-10

# COPY ibek-support/lakeshore340  lakeshore340/
# RUN  lakeshore340/install.sh 2-6

COPY ibek-support/modbus/ modbus/
RUN modbus/install.sh R3-3

COPY ibek-support/screen-epics-ioc screen-epics-ioc/
RUN screen-epics-ioc/install.sh v1.3.1

COPY ibek-support/motorNewport motorNewport/
RUN motorNewport/install.sh R1-2-1


COPY ibek-support/asynInterposeMenlo/ asynInterposeMenlo/
RUN asynInterposeMenlo/install.sh master

COPY ibek-support/epics-nds/ epics-nds/
RUN epics-nds/install.sh main

COPY ibek-support/sequencer/ sequencer/
RUN sequencer/install.sh main
COPY ibek-support/biltItest biltItest/
RUN biltItest/install.sh main

COPY ibek-support/sigmaPhiStart sigmaPhiStart/
RUN sigmaPhiStart/install.sh main

COPY ibek-support/technosoft/ technosoft/
RUN technosoft/install.sh main

COPY ibek-support/menloSyncro/ menloSyncro/
RUN menloSyncro/install.sh main

COPY ibek-support/menloLfc/ menloLfc/
RUN menloLfc/install.sh main

COPY ibek-support/menloLac menloLac
RUN menloLac/install.sh main

COPY ibek-support/icpdas icpdas
RUN icpdas/install.sh main

# get the ioc source and build it

COPY ioc/ ${SOURCE_FOLDER}/ioc
RUN cd ${IOC} && ./install.sh && make

##### runtime preparation stage ################################################

FROM developer AS runtime_prep

# get the products from the build stage and reduce to runtime assets only
# RUN ibek ioc extract-runtime-assets /assets ${SOURCE_FOLDER}/ibek*
RUN ibek ioc extract-runtime-assets /assets /epics/support/motorTechnosoft/tml_lib/config /epics/support/biltItest /epics/support/sigmaPhiStart /epics/support/menloSyncro /epics/support/menloLfc /epics/support/menloLac
# RUN ibek ioc extract-runtime-assets /assets

##### runtime stage ############################################################

FROM ${REGISTRY}/epics-base-${TARGET_ARCHITECTURE}-runtime:${BASE} AS runtime

# get runtime assets from the preparation stage
COPY --from=runtime_prep /assets /
# RUN mv /support/motorTechnosoft/tml_lib /epics/support/motorTechnosoft/

# RUN ibek ioc extract-runtime-assets /assets /usr/local/lib/x86_64-linux-gnu
# install runtime system dependencies, collected from install.sh scripts
RUN ibek support apt-install-runtime-packages 
RUN cp /epics/support/motorTechnosoft/lib/linux-x86_64/*.so /usr/lib/x86_64-linux-gnu/
ENV TARGET_ARCHITECTURE ${TARGET_ARCHITECTURE}
RUN chmod 777 -R /epics
CMD ["/bin/bash", "-c", "${IOC}/start.sh"]