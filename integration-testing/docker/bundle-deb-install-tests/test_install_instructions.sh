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

# Defaults
REPO="perfsonar-release"
declare -a OSimages=("debian:stretch" "debian:buster" "ubuntu:xenial" "ubuntu:bionic")
declare -a BUNDLES=("perfsonar-tools" "perfsonar-testpoint" "perfsonar-core" "perfsonar-centralmanagement" "perfsonar-toolkit")

# Parse CLI args
if [ -n "$1" ]; then
    # Set repo
    REPO=$1
    if [ -n "$2" ]; then
        # Set OSimage
        declare -a OSimages=("$2")
        if [ -n "$3" ]; then
            # Set Bundle
            declare -a BUNDLES=("$3")
        fi
    fi
fi

# Initialise
TEXT_STATUS=""
OUT=""
LOGS_PREFIX="logs/ps_install"
mkdir -p ${LOGS_PREFIX%%/*}
rm -f ${LOGS_PREFIX}_*.log
docker-compose down

# Loop on all OS we want to test
for OSimage in ${OSimages[@]}; do
    echo -e "OSimage: $OSimage - REPO: $REPO\n"
    TEXT_STATUS+="\n\033[1mOSimage: $OSimage - REPO: $REPO\033[0m\n"
    export OSimage REPO
    # First we build our image
    # TODO: should move to --no-cache when run on Jenkins or else?
    docker-compose build --force-rm install_test
    docker rm -f install-single-sanity
    # Loop on all bundles we want to test
    for BUNDLE in ${BUNDLES[@]}; do
        docker-compose down
        docker-compose up -d
        LABEL="$BUNDLE FROM $REPO ON $OSimage"
        LOG="${LOGS_PREFIX}_${REPO}_${OSimage}_${BUNDLE}"
        echo -e "\n\033[1m===== INSTALLING $LABEL =====\033[0m"
        echo -e "Log to $LOG.log\n"
        docker-compose exec --privileged install_test /usr/bin/ps_install_bundle.sh "$BUNDLE" >> ${LOG}.log
        STATUS=$?
        echo "$BUNDLE Tried to install; status: $STATUS"
        OUTPUT="$BUNDLE install "
        if [ "$STATUS" -eq "0" ]; then
            OUTPUT+="\033[1;32mSUCCEDED!\033[0m"
        else
            OUTPUT+="\033[1;31mFAILED!\033[0m"
        fi
        echo -e "$OUTPUT"
        TEXT_STATUS+="$OUTPUT\n"
        if [ ! "$STATUS" -eq "0" ]; then
            TEXT_STATUS+="QUITTING ... \n"
            continue
        fi
        echo -e "\n===== TESTING $LABEL ====="
        echo -e "Log to ${LOG}_test.log\n"
        docker run --privileged --name install-single-sanity --network bundle_testing --rm single-sanity install-test $BUNDLE $REPO >> ${LOG}_test.log
        SERVICE_STATUS=$?
        # TODO: try to capture output from run
        OUT+="\n"
        echo -e "OUT:\n$OUT\n"

        OUTPUT="$BUNDLE service checks "
        if [ "$SERVICE_STATUS" -eq "0" ]; then
            OUTPUT+="\033[32mRAN OK!\033[0m"
        else
            OUTPUT+="\033[31mFAILED TO RUN!\033[0m"
        fi
        echo -e "$OUTPUT"
        TEXT_STATUS+="$OUTPUT\n"
    done
done

echo -e "OUT:\n$OUT\n"
echo -e $OUT | jq .
echo -e $TEXT_STATUS

