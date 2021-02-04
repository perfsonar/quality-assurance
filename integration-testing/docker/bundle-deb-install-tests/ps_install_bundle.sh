#!/bin/bash

# Remount /tmp allowing exec
mount /tmp -o remount,exec

DEBIAN_FRONTEND=noninteractive
echo "Set DEBIAN_FRONTEND: $DEBIAN_FRONTEND"

apt-get -y install apt-utils

echo "Executing 'apt-get -y update'"
apt-get -y update

apt-get install -y wget
apt-get install -y gnupg

cd /etc/apt/sources.list.d/
wget -qO - http://downloads.perfsonar.net/debian/perfsonar-official.gpg.key | apt-key add -
wget -qO - http://downloads.perfsonar.net/debian/perfsonar-snapshot.gpg.key | apt-key add -


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

echo "Executing 'apt-get -y update'"
apt-get -y update

CMD="/usr/bin/apt-get install -y $BUNDLE"

echo "Executing '$CMD'"

eval $CMD
