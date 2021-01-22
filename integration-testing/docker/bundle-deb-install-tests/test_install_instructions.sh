#!/usr/bin/bash

#######
# test_install_instructions.sh
# REQUIRES:
#  - jq
#  - single-sanity to be built on the same host
# This script is designed to test the rpm bundle installation process
# documented on the perfsonar docs site:
# http://docs.perfsonar.net/install_centos.html
# The steps in the script recreate what the instructions ask for, but if
# the instructions are changed, this script will need to be updated to match
# Can optionally specify a repo to use. By default, uses the production repo. 
# Debian Options:
# - perfsonar-release 
# - perfsonar-patch-snapshot
# - perfsonar-minor-snapshot
# - perfsonar-patch-staging
#######

# default repo
# if blank/not specified, PRODUCTION is used
REPO="perfsonar-release"

# set repo if commandline argument is set
if [ -n "$1" ]; then
    REPO=$1
fi

echo "REPO: $REPO"

#declare -a BUNDLES=("perfsonar-testpoint")
declare -a BUNDLES=("perfsonar-core")
#declare -a BUNDLES=("perfsonar-testpoint", "perfsonar-core")
#declare -a BUNDLES=("perfsonar-tools" "perfsonar-testpoint" "perfsonar-core" "perfsonar-centralmanagement" "perfsonar-toolkit")

TEXT_STATUS=""
OUT=""
docker-compose down
docker-compose build --no-cache --force-rm debian_clean
docker rm -f install-single-sanity
for BUNDLE in ${BUNDLES[@]}; do
    echo "BUILD BUNDLE $BUNDLE"
    docker-compose up -d
    #CONTAINER="$BUNDLE-$REPO"
    #CONTAINER="$BUNDLE"
    LABEL="$BUNDLE-$REPO"
    CONTAINER="deb-install-transient"
    echo "CONTAINER: $CONTAINER"
    docker-compose exec --privileged debian_clean /usr/bin/ps_install_bundle.sh "$BUNDLE" "$REPO"
    STATUS=$?
    echo "LABEL: $LABEL"
    #docker run --privileged --name install-single-sanity --network bundle_testing --rm single-sanity $CONTAINER $BUNDLE $REPO
    SERVICE_STATUS=$?
    OUT+="\n"
    echo "LABEL: $LABEL"
    echo -e "OUT:\n$OUT\n"

    echo "$BUNDLE Tried to install; status: $STATUS"
    if [ "$STATUS" -eq "0" ]; then
        echo "$BUNDLE install SUCCEDED!"
        TEXT_STATUS+="$BUNDLE install SUCCEEDED!\n"
        #exit;
    else
        echo "$BUNDLE install FAILED!"
        TEXT_STATUS+="$BUNDLE install FAILED!\n"
        TEXT_STATUS+="QUITTING ... \n"
        exit
    fi
    if [ "$SERVICE_STATUS" -eq "0" ]; then
        echo "$BUNDLE service checks RAN OK!"
        TEXT_STATUS+="$BUNDLE service checks RAN OK!\n"
        #exit;
    else
        echo "$BUNDLE service checks FAILED TO RUN!"
        TEXT_STATUS+="$BUNDLE services FAILED TO RUN!\n"
    fi
    docker-compose down

    echo -e $TEXT_STATUS
done
    echo -e "OUT:\n$OUT\n"
    echo -e $OUT | jq .

echo -e $TEXT_STATUS

