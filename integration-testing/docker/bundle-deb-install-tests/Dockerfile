FROM jrei/systemd-debian:9
ENV container docker
ARG bundle
ARG repo

RUN echo "BUNDLE!!!: $bundle"

RUN echo "REPO!!!: $repo"

#Copy test script
COPY ./ps_install_bundle.sh /usr/bin/ps_install_bundle.sh
RUN chmod 755 /usr/bin/ps_install_bundle.sh

# Configure APT
# RUN cd /etc/apt/sources.list.d/
# TODO: need sudo for wget calls?
#RUN apt list installed

# update apt cache
# RUN apt-get -y update
# RUN apt-get -y install apt-utils

# RUN apt-get install -y wget
# #RUN apt-get install -y gnupg
#
# RUN wget -qO - http://downloads.perfsonar.net/debian/perfsonar-official.gpg.key | apt-key add -
# RUN wget -qO - http://downloads.perfsonar.net/debian/perfsonar-snapshot.gpg.key | apt-key add -

#RUN wget http://downloads.perfsonar.net/debian/perfsonar-release.list

#shared volumes
VOLUME /sys/fs/cgroup

#Let docker know that pscheduler listens on 443
EXPOSE 443

# WORK AROUND A DEBIAN DOCKER ISSUE
# https://stackoverflow.com/questions/46247032/how-to-solve-invoke-rc-d-policy-rc-d-denied-execution-of-start-when-building
RUN printf '#!/bin/sh\nexit 0' > /usr/sbin/policy-rc.d

# start systemd
CMD ["/lib/systemd/systemd"]
