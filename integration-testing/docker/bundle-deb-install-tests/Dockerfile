# perfSONAR install ready image

# OS image to use as a base
ARG OSimage=debian:stretch
FROM $OSimage

# Some sane defaults
ENV container docker
ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive

# perfSONAR repository needs to be given as argument
ARG REPO
RUN echo "OSimage is: $OSimage"
RUN echo "REPO is: $REPO"

# Use a proxy to download packages, for example https://github.com/sameersbn/docker-squid
#ENV http_proxy=http://172.17.0.1:3128 \
#    https_proxy=http://172.17.0.1:3128 \
#    no_proxy=localhost,127.0.0.1

# Update apt cache, install some packages and do some cleanup
RUN apt-get update && apt-get install -y \
        apt-utils \
        gnupg \
        systemd \
        systemd-sysv \
        wget && \
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
RUN echo "REPO!!!: $REPO"
RUN if [ "$REPO" = "perfsonar-release" ] ; \
    then wget -qO - http://downloads.perfsonar.net/debian/perfsonar-official.gpg.key | apt-key add - ; \
    else wget -qO - http://downloads.perfsonar.net/debian/perfsonar-snapshot.gpg.key | apt-key add - ; \
    fi
RUN wget -P /etc/apt/sources.list.d/ http://downloads.perfsonar.net/debian/$REPO.list

# Copy test script
COPY ./ps_install_bundle.sh /usr/bin/ps_install_bundle.sh
RUN chmod 755 /usr/bin/ps_install_bundle.sh

# Start systemd
CMD ["/lib/systemd/systemd"]

