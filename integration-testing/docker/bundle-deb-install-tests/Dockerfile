# perfSONAR install ready image

### Globally scoped ARG, defined here to be available to use in FROM statements
# Do we want to use a proxy?
ARG useproxy=no
# OS image to use as a base
ARG OSimage=debian:stretch
FROM ${OSimage} AS base

# Some sane defaults
ENV container docker
ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive

# If you want to use a proxy to speed up download both at build time and test time (docker run)
# Trick built on top of https://medium.com/@tonistiigi/advanced-multi-stage-build-patterns-6f741b852fae
FROM base AS proxy-yes
ARG proxy
ENV http_proxy=http://${proxy}
ENV https_proxy=https://${proxy}
ENV no_proxy=localhost,127.0.0.1

FROM base AS proxy-no
ENV http_proxy=
ENV https_proxy=
ENV no_proxy=

# Update apt cache, install some packages and do some cleanup
FROM proxy-${useproxy} AS install-image
RUN echo "Install image proxy is: ${https_proxy:-none}"
RUN apt-get update && apt-get install -y \
        apt-utils \
        curl \
        gnupg \
        systemd \
        systemd-sysv && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# To make systemd work properly
# From https://github.com/j8r/dockerfiles/tree/master/systemd
RUN cd /lib/systemd/system/sysinit.target.wants/ \
    && ls | grep -v systemd-tmpfiles-setup | xargs rm -f $1

# List for D9, D10, U16, U18 and U20
RUN rm -f /lib/systemd/system/multi-user.target.wants/* \
    /etc/systemd/system/*.wants/* \
    /lib/systemd/system/anaconda.target.wants/* \
    /lib/systemd/system/basic.target.wants/* \
    /lib/systemd/system/local-fs.target.wants/* \
    /lib/systemd/system/plymouth* \
    /lib/systemd/system/sockets.target.wants/*udev* \
    /lib/systemd/system/sockets.target.wants/*initctl* \
    /lib/systemd/system/sysinit.target.wants/systemd-tmpfiles-setup* \
    /lib/systemd/system/systemd-update-utmp*

# Shared volume needed for systemd
VOLUME /sys/fs/cgroup

# Let docker know that pscheduler listens on 443
EXPOSE 443

# WORK AROUND A DEBIAN/UBUNTU DOCKER ISSUE
# https://stackoverflow.com/questions/46247032/how-to-solve-invoke-rc-d-policy-rc-d-denied-execution-of-start-when-building
RUN printf '#!/bin/sh\nexit 0' > /usr/sbin/policy-rc.d

# Configure perfSONAR repository and GPG key
ARG REPO
RUN if [ "$REPO" = "perfsonar-release" ] ; \
    then curl http://downloads.perfsonar.net/debian/perfsonar-official.gpg.key | apt-key add - ; \
    else curl http://downloads.perfsonar.net/debian/perfsonar-snapshot.gpg.key | apt-key add - ; \
    fi
RUN curl -o /etc/apt/sources.list.d/$REPO.list http://downloads.perfsonar.net/debian/$REPO.list

# Copy test script
COPY ./ps_install_bundle.sh /usr/bin/ps_install_bundle.sh
RUN chmod 755 /usr/bin/ps_install_bundle.sh

# Start systemd
CMD ["/lib/systemd/systemd"]

