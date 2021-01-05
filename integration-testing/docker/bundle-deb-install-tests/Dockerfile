FROM jrei/systemd-debian:9
ENV container docker
ARG bundle
ARG repo

RUN echo "BUNDLE!!!: $bundle"

RUN echo "REPO!!!: $repo"

#Copy test script
COPY ./ps_install_bundle.sh /usr/bin/ps_install_bundle.sh
RUN chmod 755 /usr/bin/ps_install_bundle.sh

RUN dpkg -l

# Configure APT
RUN cd /etc/apt/sources.list.d/
# TODO: need sudo for wget calls?
#RUN apt list installed

# update apt cache
RUN apt-get update

RUN apt-get install -y wget
RUN apt-get install -y gnupg

RUN wget -qO - http://downloads.perfsonar.net/debian/perfsonar-official.gpg.key | apt-key add -
#RUN wget http://downloads.perfsonar.net/debian/perfsonar-release.list

#shared volumes
VOLUME /sys/fs/cgroup

#Let docker know that pscheduler listens on 443
EXPOSE 443

#Keep container running
#CMD tail -f /dev/null
# CMD ["/usr/sbin/init"]
CMD ["/lib/systemd/systemd"]
