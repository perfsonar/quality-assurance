FROM centos:7
ENV container docker
ARG bundle
ARG repo

RUN echo "BUNDLE!!!: $bundle"

RUN echo "REPO!!!: $repo"

#Copy test script
COPY ./ps_install_bundle.sh /usr/bin/ps_install_bundle.sh
RUN chmod 755 /usr/bin/ps_install_bundle.sh

#cleanup to enable systemd
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
    systemd-tmpfiles-setup.service ] || rm -f $i; done); \
    rm -f /lib/systemd/system/multi-user.target.wants/*;\
    rm -f /etc/systemd/system/*.wants/*;\
    rm -f /lib/systemd/system/local-fs.target.wants/*; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
    rm -f /lib/systemd/system/basic.target.wants/*;\
    rm -f /lib/systemd/system/anaconda.target.wants/*;

#Install repos we will use in testing
RUN yum clean all && \
    yum update -y && \
    yum install -y epel-release && \
    yum install -y http://linux.mirrors.es.net/perfsonar/el7/x86_64/4/packages/perfSONAR-repo-0.10-1.noarch.rpm
    #yum install -y http://software.internet2.edu/rpms/el7/x86_64/4.2.4/RPMS/perfSONAR-repo-0.9-1.noarch.rpm && \
    #yum install -y http://linux.mirrors.es.net/perfsonar/el7/x86_64/4/packages/perfSONAR-repo-nightly-minor-0.10-1.noarch.rpm 
    #yum install -y http://linux.mirrors.es.net/perfsonar/el7/x86_64/4/packages/perfSONAR-repo-nightly-patch-0.9-1.noarch.rpm && \
    #yum install -y http://linux.mirrors.es.net/perfsonar/el7/x86_64/4/packages/perfSONAR-repo-staging-0.9-1.noarch.rpm && \
    #sed -i 's/enabled = 1/enabled = 0/' /etc/yum.repos.d/perfSONA*.repo && \
    #yum clean all && \ 
    #yum install -y perfsonar-testpoint
    #yum install -y $bundle


#shared volumes
VOLUME /sys/fs/cgroup

#Let docker know that pscheduler listens on 443
EXPOSE 443

#Keep container running
#CMD tail -f /dev/null
CMD ["/usr/sbin/init"]
