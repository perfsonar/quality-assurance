#!/usr/bin/env bash

#######
# test_install_instructions.sh [repo]
# REQUIRES:
#  - jq
#  - single-sanity to be built on the same host, if it's enabled
# This script is designed to test the deb bundle installation process
# documented on the perfsonar docs site:
# http://docs.perfsonar.net/install_debian.html
# The steps in the script recreate what the instructions ask for, but if
# the instructions are changed, this script will need to be updated to match
# Can optionally specify a repo to use. By default, uses the production repo.
# Debian repo Options:
# - perfsonar-release (PRODUCTION)
# - perfsonar-patch-snapshot
# - perfsonar-minor-snapshot
# - perfsonar-patch-staging
# - perfsonar-minor-staging
#######

# default OS, if blank/not specified, Debian 9 is used
declare -a OSimages=("debian:stretch" "debian:buster" "ubuntu:xenial" "ubuntu:bionic")

# default repo, if blank/not specified, PRODUCTION is used
REPO="perfsonar-release"

# set repo if commandline argument is set
if [ -n "$1" ]; then
    REPO=$1
fi

# DECLARE WHICH BUNDLE(S) TO INSTALL
#declare -a BUNDLES=("perfsonar-testpoint")
#declare -a BUNDLES=("perfsonar-tools" "perfsonar-toolkit")
declare -a BUNDLES=("perfsonar-tools" "perfsonar-testpoint" "perfsonar-core" "perfsonar-centralmanagement" "perfsonar-toolkit")

TEXT_STATUS=""
OUT=""
docker-compose down
# Loop on all OS we want to test
for OSimage in ${OSimages[@]}; do
    echo -e "OSimage: $OSimage - REPO: $REPO\n"
    TEXT_STATUS+="\nOSimage: $OSimage - REPO: $REPO\n"
    export OSimage REPO
    # First we build our image
    # TODO: should move to --no-cache when run on Jenkins or else?
    docker-compose build --force-rm install_test
    docker rm -f install-single-sanity
    # Loop on all bundles we want to test
    for BUNDLE in ${BUNDLES[@]}; do
        docker-compose down
        docker-compose up -d
        LABEL="$BUNDLE from $REPO on $OSimage"
        echo -e "\n===== INSTALLING $LABEL =====\n"
        docker-compose exec --privileged install_test /usr/bin/ps_install_bundle.sh "$BUNDLE"
        STATUS=$?
        echo "$BUNDLE Tried to install; status: $STATUS"
        if [ "$STATUS" -eq "0" ]; then
            echo "$BUNDLE install SUCCEDED!"
            TEXT_STATUS+="$BUNDLE install SUCCEEDED!\n"
        else
            echo "$BUNDLE install FAILED!"
            TEXT_STATUS+="$BUNDLE install FAILED!\n"
            TEXT_STATUS+="QUITTING ... \n"
            continue
        fi
        echo -e "\n===== TESTING $LABEL =====\n"
        docker run --privileged --name install-single-sanity --network bundle_testing --rm single-sanity install-test $BUNDLE $REPO
        SERVICE_STATUS=$?
        # TODO: try to capture output from run
        OUT+="\n"
        echo -e "OUT:\n$OUT\n"

        if [ "$SERVICE_STATUS" -eq "0" ]; then
            echo "$BUNDLE service checks RAN OK!"
            TEXT_STATUS+="$BUNDLE service checks RAN OK!\n"
        else
            echo "$BUNDLE service checks FAILED TO RUN!"
            TEXT_STATUS+="$BUNDLE services FAILED TO RUN!\n"
        fi

        echo -e $TEXT_STATUS
    done
done

echo -e "OUT:\n$OUT\n"
echo -e $OUT | jq .
echo -e $TEXT_STATUS

