#!/bin/bash

DEBIAN_FRONTEND=noninteractive

printf '#!/bin/sh\nexit 0' > /usr/sbin/policy-rc.d

BUNDLE=$1
if [ -n "$2" ]; then
    REPO=$2
    if [ ! -z $REPO ]
    then
        echo "Installing repo: $REPO"
        cd /etc/apt/sources.list.d/
        wget http://downloads.perfsonar.net/debian/$REPO.list
    else
        echo "REPO not specified; using PRODUCTION";
        cd /etc/apt/sources.list.d/
        wget http://downloads.perfsonar.net/debian/perfsonar-release.list
    fi
fi
echo "Executing apt-get install \"$BUNDLE\""

apt-get update
apt-get install -y "$BUNDLE"

