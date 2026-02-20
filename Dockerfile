ARG IMAGE_EXT
ARG BASE=7.0.9ec4
ARG REGISTRY_EC=ghcr.io/epics-containers
ARG TAGVERSION=latest
ARG REGISTRY=ghcr.io/infn-epics
ARG DEVELOPER=${REGISTRY}/infn-epics-ioc-base${IMAGE_EXT}:latest
ARG RUNTIME=${REGISTRY_EC}/epics-base${IMAGE_EXT}-runtime:${BASE}

##### build stage ##############################################################
FROM  ${DEVELOPER} AS developer
ARG TAGVERSION
ENV TAGVERSION=${TAGVERSION}

# The devcontainer mounts the project root to /epics/generic-source
# Using the same location here makes devcontainer/runtime differences transparent.
ENV SOURCE_FOLDER=/epics/generic-source
# connect ioc source folder to its know location
COPY requirements.txt requirements.txt
RUN uv pip install --upgrade -r requirements.txt
# Get the current version of ibek
##RUN uv pip install --upgrade epik8s-tools

WORKDIR ${SOURCE_FOLDER}/ibek-support-infn
# Single COPY to keep layer depth under Docker's 127-layer hard limit.
COPY ibek-support-infn/ ./


# Install all support modules in a single layer
# apt-get update first to avoid stale 404s from the base image cache
RUN apt-get update && \
    ansible.sh epics-nds && \
    ansible.sh technosoft && \
    ansible.sh asynInterposeMenlo && \
    ansible.sh menloSyncro && \
    ansible.sh menloLfc && \
    ansible.sh menloLac && \
    ansible.sh AgilentXgs600 && \
    ansible.sh biltItest && \
    ansible.sh sigmaPhiStart && \
    ansible.sh icpdas && \
    ansible.sh easy-driver-epics && \
    ansible.sh kima-undulator && \
    ansible.sh agilentipcmini && \
    ansible.sh agilent4uhv && \
    ansible.sh smc && \
    ansible.sh tpg300_500 && \
    ansible.sh Tektronix_MSO58LP && \
    ansible.sh caenelsPS && \
    ansible.sh ocemPS && \
    ansible.sh motorMicos && \
    ansible.sh cagateway && \
    ansible.sh hazemeyer && \
    ansible.sh ppt-modulator && \
    ansible.sh scandinova-scandicat-mod && \
    ansible.sh ocemE642 && \
    ansible.sh plc-elinp && \
    ansible.sh psEEI && \
    ansible.sh maccaferriPS && \
    ansible.sh danfysik && \
    ansible.sh polyscience && \
    ansible.sh mps

#     ansible.sh technosoft-asyn && 

COPY ioc/ ${SOURCE_FOLDER}/ioc
RUN ansible.sh ioc

COPY ibek-templates/templates /epics/support/templates/ibek-templates
COPY epics-support-template-infn /epics/support/templates/infn-support-templates
RUN apt-get update && apt-get install -y openssh-server lshw nvidia-utils-550 sudo curl && \
    mkdir /var/run/sshd && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    curl -o /usr/bin/yq -L https://github.com/mikefarah/yq/releases/download/v4.44.2/yq_linux_amd64 && chmod +x /usr/bin/yq && \
    ibek support apt-install iputils-ping iproute2 telnet && \
    ibek support add-runtime-packages iputils-ping iproute2 telnet ca-certificates openssh-client curl
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]

##### runtime preparation stage ################################################
FROM developer AS runtime_prep
ARG TAGVERSION
ENV TAGVERSION=${TAGVERSION}

# get the products from the build stage and reduce to runtime assets only
# RUN ibek ioc extract-runtime-assets /assets ${SOURCE_FOLDER}/ibek*
RUN ibek ioc extract-runtime-assets /assets /python /epics/support/ibek-templates /epics/support/templates /epics/support/motorTechnosoft /epics/support/technosoft-asyn
# RUN ibek ioc extract-runtime-assets /assets

RUN date --utc +%Y-%m-%dT%H:%M:%SZ > /assets/BUILD_INFO.txt && echo "TAG ${TAGVERSION}" >> /assets/BUILD_INFO.txt
##### runtime stage ############################################################
FROM ${RUNTIME} AS runtime
ARG TAGVERSION
ENV TAGVERSION=${TAGVERSION}
# RUN groupadd -g 1000 epics && useradd -m -u 1000 -g 1000 epics
# get runtime assets from the preparation stage
COPY --from=runtime_prep /assets /
# install runtime system dependencies, collected from install.sh scripts
RUN ibek support apt-install curl
RUN ibek support apt-install-runtime-packages
RUN curl -o /usr/bin/yq -L https://github.com/mikefarah/yq/releases/download/v4.44.2/yq_linux_amd64 && chmod +x /usr/bin/yq && \
    cp /epics/support/motorTechnosoft/lib/linux-x86_64/*.so /usr/lib/x86_64-linux-gnu/ && \
    ( cp /epics/support/technosoft-asyn/tml_lib/lib/*.so /usr/lib/x86_64-linux-gnu/ 2>/dev/null || true )
RUN chown 1000.1000 -R /epics
CMD ["/bin/bash", "-c", "${IOC}/start.sh"]
