FROM perfsonar/testpoint:latest

RUN yum -y install perl-LWP-Protocol-https
    #yum -y upgrade && \
    #yum -y install perl-LWP-Protocol-https
#    apt-get install -y libjson-perl jq

RUN mkdir /app
RUN mkdir /app/logs
WORKDIR /app


COPY sanity.pl /app
COPY test_configs/testbed-nightly-psconfig.json /app

#CMD ["ls", "-l", "/app"]

ENTRYPOINT ["/usr/bin/perl", "-I /usr/lib/perfsonar/lib", "sanity.pl"]
