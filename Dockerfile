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

# Get the current version of ibek
RUN uv pip install --upgrade epik8s-tools

WORKDIR ${SOURCE_FOLDER}/ibek-support-infn
# COPY ibek-support-infn/_global/ _global

COPY ibek-support-infn/epics-nds/ epics-nds/
RUN ansible.sh epics-nds

COPY ibek-support-infn/asynInterposeMenlo/ asynInterposeMenlo/
RUN ansible.sh asynInterposeMenlo

COPY ibek-support-infn/menloSyncro/ menloSyncro/
RUN ansible.sh menloSyncro


COPY ibek-support-infn/menloLfc/ menloLfc/
RUN ansible.sh menloLfc

COPY ibek-support-infn/menloLac menloLac
RUN ansible.sh menloLac

COPY ibek-support-infn/AgilentXgs600 AgilentXgs600
RUN ansible.sh AgilentXgs600

#COPY ibek-support-infn/screen-epics-ioc screen-epics-ioc/
# RUN ansible.sh screen-epics-ioc

COPY ibek-support-infn/biltItest biltItest/
RUN ansible.sh biltItest

COPY ibek-support-infn/sigmaPhiStart sigmaPhiStart/
RUN ansible.sh sigmaPhiStart

COPY ibek-support-infn/icpdas icpdas
RUN ansible.sh icpdas

COPY ibek-support-infn/easy-driver-epics easy-driver-epics
RUN ansible.sh easy-driver-epics

COPY ibek-support-infn/kima-undulator kima-undulator
RUN ansible.sh kima-undulator

COPY ibek-support-infn/agilentipcmini agilentipcmini
RUN ansible.sh agilentipcmini

COPY ibek-support-infn/agilent4uhv agilent4uhv
RUN ansible.sh agilent4uhv


COPY ibek-support-infn/smc smc
RUN ansible.sh smc

COPY ibek-support-infn/technosoft/ technosoft/
RUN ansible.sh technosoft


COPY ibek-support-infn/tpg300_500 tpg300_500
RUN ansible.sh tpg300_500

COPY ibek-support-infn/Tektronix_MSO58LP/ Tektronix_MSO58LP/
RUN ansible.sh Tektronix_MSO58LP

COPY ibek-support-infn/caenelsPS caenelsPS/
RUN ansible.sh caenelsPS

COPY ibek-support-infn/ocemPS ocemPS/
RUN ansible.sh ocemPS

COPY ibek-support-infn/motorMicos motorMicos/
RUN ansible.sh motorMicos

COPY ibek-support-infn/cagateway cagateway
RUN ansible.sh cagateway

COPY ibek-support-infn/hazemeyer hazemeyer
RUN ansible.sh hazemeyer

COPY ibek-support-infn/ppt-modulator ppt-modulator
RUN ansible.sh ppt-modulator

# COPY ibek-support-infn/hazemeyer-lnf hazemeyer
# RUN ansible.sh hazemeyer

COPY ioc/ ${SOURCE_FOLDER}/ioc
RUN ansible.sh ioc

COPY ibek-templates/templates /epics/support/templates/ibek-templates
COPY epics-support-template-infn /epics/support/templates/infn-support-templates
RUN apt-get update && apt-get install -y openssh-server lshw nvidia-utils-550 sudo curl
# RUN groupadd -g 1000 epics && useradd -m -u 1000 -g 1000 epics -s /bin/bash && echo "epics:epics" | chpasswd
RUN mkdir /var/run/sshd
# Allow password login
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN curl -o /usr/bin/yq -L https://github.com/mikefarah/yq/releases/download/v4.44.2/yq_linux_amd64 && chmod +x /usr/bin/yq

# add some debugging tools for the developer target
RUN ibek support apt-install iputils-ping iproute2 telnet;ibek support add-runtime-packages iputils-ping iproute2 telnet python3-distutils ca-certificates python3.10-venv  openssh-client curl
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]

##### runtime preparation stage ################################################
FROM developer AS runtime_prep
ARG TAGVERSION
ENV TAGVERSION=${TAGVERSION}

# get the products from the build stage and reduce to runtime assets only
# RUN ibek ioc extract-runtime-assets /assets ${SOURCE_FOLDER}/ibek*
RUN ibek ioc extract-runtime-assets /assets /python /epics/support/ibek-templates /epics/support/templates /epics/support/motorTechnosoft
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
RUN curl -o /usr/bin/yq -L https://github.com/mikefarah/yq/releases/download/v4.44.2/yq_linux_amd64 && chmod +x /usr/bin/yq

RUN cp /epics/support/motorTechnosoft/lib/linux-x86_64/*.so /usr/lib/x86_64-linux-gnu/
RUN chown 1000.1000 -R /epics
CMD ["/bin/bash", "-c", "${IOC}/start.sh"]
