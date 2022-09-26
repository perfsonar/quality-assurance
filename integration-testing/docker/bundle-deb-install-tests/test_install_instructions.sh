#!/usr/bin/env bash

#######
# test_install_instructions.sh [repo] [osimage] [bundle]
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
LOGS_PREFIX="logs/ps_install"
REPO="perfsonar-release"
OSimage="debian:buster"
declare -a OSimages=("debian:buster" "debian:bullseye" "ubuntu:bionic" "ubuntu:focal" "ubuntu:jammy")
#declare -a BUNDLES=("perfsonar-tools" "perfsonar-testpoint" "perfsonar-core" "perfsonar-centralmanagement" "perfsonar-toolkit")
# Only testpoint is supported on Debian/Ubuntu for 5.0
declare -a BUNDLES=("perfsonar-tools" "perfsonar-testpoint")

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
if [ -n "$proxy" ]; then
    # If $proxy is set, then we will use it
    useproxy=with
else
    useproxy=without
fi
export OSimage REPO useproxy
# And cleanup before testing
mkdir -p ${LOGS_PREFIX%%/*}
rm -f ${LOGS_PREFIX}_*.log
docker compose down

# First we build our images
# TODO: should move to --no-cache when run on Jenkins or else?
docker buildx bake
docker compose up -d

echo -e "\n\n\033[1;33m*** Starting testing perfSONAR bundles from $REPO ***\033[0m\n"
# Loop on all OS we want to test
for OSimage in ${OSimages[@]}; do
    echo -e "\n\033[1;35m================\033[0;35m\nOSimage: $OSimage - REPO: $REPO\n\033[1m================\033[0m\n"
    TEXT_STATUS+="\n\033[1mOSimage: $OSimage - REPO: $REPO\033[0m\n"
    # Loop on all bundles we want to test
    for BUNDLE in ${BUNDLES[@]}; do
        LABEL="$BUNDLE FROM $REPO ON $OSimage"
        LOG="${LOGS_PREFIX}_${REPO}_${OSimage}_${BUNDLE}"
        echo -e "\n\033[1m===== INSTALLING ${LABEL} =====\033[0m"
        echo -e "Log to ${LOG}.log\n"
        docker compose exec install_test_${OSimage##*:} /usr/local/bin/ps_install_bundle.sh "$BUNDLE" >> ${LOG}.log
        STATUS=$?
        OUTPUT="$BUNDLE install "
        if [ "$STATUS" -eq "0" ]; then
            OUTPUT+="\033[1;32mSUCCEEDED!\033[0m"
        else
            echo "\033[0;31m$BUNDLE failed to install with status: $STATUS\033[0m"
            echo -e "Check the logs and then you can try to debug what went wrong by running:\n./debug_install.sh $REPO $OSimage $BUNDLE"
            OUTPUT+="\033[1;31mFAILED!\033[0m"
        fi
        echo -e "$OUTPUT"
        TEXT_STATUS+="$OUTPUT\n"
        if [ ! "$STATUS" -eq "0" ]; then
            TEXT_STATUS+="QUITTING ... \n"
            continue
        fi
        echo -e "\n\033[1m===== TESTING \033[0m$LABEL ====="
        echo -e "Log to ${LOG}_test.log\n"
        docker compose run single_sanity install_test_${OSimage##*:} $REPO >> ${LOG}_test.log 2>&1
        SERVICE_STATUS=$?
        # TODO: try to capture output from run
        OUT+="\n"
        #echo -e "OUT:\n$OUT\n"

        OUTPUT="$BUNDLE service checks "
        if [ "$SERVICE_STATUS" -eq "0" ]; then
            OUTPUT+="\033[1;32mRAN OK!\033[0m"
        else
            OUTPUT+="\033[1;31mFAILED TO RUN!\033[0m"
        fi
        echo -e "$OUTPUT\n"
        TEXT_STATUS+="$OUTPUT\n"
    done
done

echo -e "\nNow stopping containers."
docker compose down
echo -e "OUT:\n$OUT\n"
echo -e $OUT | jq .
echo -e $TEXT_STATUS

