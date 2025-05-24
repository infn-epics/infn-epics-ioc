ARG IMAGE_EXT
ARG BASE=7.0.8ad3
ARG REGISTRY_EC=ghcr.io/epics-containers

ARG REGISTRY=ghcr.io/infn-epics
ARG DEVELOPER=${REGISTRY}/infn-epics-ioc-base${IMAGE_EXT}:latest
ARG RUNTIME=${REGISTRY_EC}/epics-base${IMAGE_EXT}-runtime:${BASE}

##### build stage ##############################################################
FROM  ${DEVELOPER} AS developer

# The devcontainer mounts the project root to /epics/generic-source
# Using the same location here makes devcontainer/runtime differences transparent.
ENV SOURCE_FOLDER=/epics/generic-source
# connect ioc source folder to its know location

# Get the current version of ibek
RUN pip install --upgrade -r requirements.txt

WORKDIR ${SOURCE_FOLDER}/ibek-support-infn

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

# RUN ansible.sh ioc
COPY ibek-templates/templates /epics/support/templates/ibek-templates
COPY epics-support-template-infn /epics/support/templates/infn-support-templates

##### runtime preparation stage ################################################
FROM developer AS runtime_prep

# get the products from the build stage and reduce to runtime assets only
# RUN ibek ioc extract-runtime-assets /assets ${SOURCE_FOLDER}/ibek*
RUN ibek ioc extract-runtime-assets /assets /epics/support/ibek-templates /epics/support/templates /epics/support/motorTechnosoft/tml_lib/config /epics/support/biltItest /epics/support/agilent4uhv /epics/support/AgilentXgs600 /epics/support/sigmaPhiStart /epics/support/menloSyncro /epics/support/menloLfc /epics/support/menloLac
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
