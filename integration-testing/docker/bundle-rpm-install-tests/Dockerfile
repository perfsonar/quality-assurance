# perfSONAR install ready image

### Globally scoped ARG, defined here to be available to use in FROM statements
# Do we want to use a proxy?
ARG useproxy=without
# TODO: move to pS provided base OS image
# OS image to use as a base
ARG OSimage=centos:7
FROM ${OSimage} AS base

# Some sane defaults
ENV LC_ALL=C
ENV container docker

# If you want to use a proxy to speed up download both at build time and test time (docker run)
# Trick built on top of https://medium.com/@tonistiigi/advanced-multi-stage-build-patterns-6f741b852fae
FROM base AS base-with-proxy
ARG proxy
ENV http_proxy=http://${proxy}
ENV https_proxy=https://${proxy}
ENV no_proxy=localhost,127.0.0.1

FROM base AS base-without-proxy
ENV http_proxy=
ENV https_proxy=
ENV no_proxy=

FROM base-${useproxy}-proxy AS install-image
RUN echo "Install image proxy is: ${https_proxy:-none}"
RUN yum update -y && yum install -y \
        epel-release \
        curl \
        gnupg \
        systemd \
        systemd-sysv && \
    yum autoremove -y && \
    yum clean all && \
    rm -rf /tmp/* /var/tmp/*

# To make systemd work properly
# From https://github.com/j8r/dockerfiles/tree/master/systemd
# List for C7
RUN cd /lib/systemd/system/sysinit.target.wants/; \
    for i in *; do [ $i = systemd-tmpfiles-setup.service ] || rm -f $i; done
RUN rm -f /lib/systemd/system/multi-user.target.wants/* \
    /etc/systemd/system/*.wants/* \
    /lib/systemd/system/local-fs.target.wants/* \
    /lib/systemd/system/sockets.target.wants/*udev* \
    /lib/systemd/system/sockets.target.wants/*initctl* \
    /lib/systemd/system/basic.target.wants/* \
    /lib/systemd/system/anaconda.target.wants/*

## REPO:
# perfSONAR-repo
# perfSONAR-repo-nightly-minor
# perfSONAR-repo-nightly-patch
# perfSONAR-repo-staging

# Configure perfSONAR repository and GPG key
ARG REPO
RUN echo "Adding perfSONAR repository: $REPO"
RUN rpm -hUv http://software.internet2.edu/rpms/el7/x86_64/latest/packages/perfSONAR-${REPO#"perfsonar-"}-0.10-1.noarch.rpm && \
    yum update -y && \
    yum autoremove -y && \
    yum clean all && \
    rm -rf /tmp/* /var/tmp/*

# Copy test script
COPY ./ps_install_bundle.sh /usr/local/bin/ps_install_bundle.sh
RUN chmod 755 /usr/local/bin/ps_install_bundle.sh

# Let docker know that pscheduler listens on 443
EXPOSE 443

# Start systemd
CMD ["/usr/sbin/init"]
