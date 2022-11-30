#!/usr/bin/env bash

# Usage info
show_help() {
    cat << EOF
    Usage: ${0##*/} -D -r [repo] -o [osimage] -b [bundle]

    This script will build docker images and launch a git repo build in a container
    Requirements: Docker and jq

    This script is designed to test the rpm bundle installation process
    documented on the perfsonar docs site:
    https://docs.perfsonar.net/install_centos.html

    Options:
        -D enable debug mode, drop into a shell if the install cannot complete
        -r [repo] one of:
            - perfsonar-repo (PRODUCTION)
            - perfsonar-repo-nightly-minor
            - perfsonar-repo-nightly-patch
            - perfsonar-repo-staging
        -o [osimage] a known CentOS Docker image tag like centos:7
        -b [bundle] a known perfSONAR bundle of packages like perfsonar-testpoint or perfsonar-toolkit

EOF
}

# Container debug shell
container_debug() {
    local container=$1
    docker compose cp ./debug-pscheduler-api.sh $container:/usr/local/bin/
    docker compose exec $container apt-get install -y less vim
    docker compose exec $container bash
}

# Defaults
LOGS_PREFIX="logs/ps_install"
REPO="perfsonar-repo"
declare -a OSimages=("centos:7")
declare -a BUNDLES=("perfsonar-tools" "perfsonar-testpoint" "perfsonar-archive" "perfsonar-dashboards" "perfsonar-core" "perfsonar-centralmanagement" "perfsonar-toolkit")
#declare -a BUNDLES=("perfsonar-psconfig-web-admin-ui perfsonar-psconfig-web-admin-publisher" "perfsonar-tools" "perfsonar-core" "perfsonar-testpoint" "perfsonar-centralmanagement" "perfsonar-toolkit")
debug=false

# Parsing options
while getopts "Dhr:o:b:" OPT; do
    case $OPT in
        D) debug=true ;;
        b) BUNDLES=("$OPTARG") ;;
        o) OSimages=("$OPTARG") ;;
        r) REPO=$OPTARG ;;
        h)
            show_help >&2
            exit 1 ;;
    esac
done

# Initialise
OSimage=${OSimages[0]}
TEXT_STATUS=""
OUT=""
if [ -n "$proxy" ]; then
    # If $proxy is set, then we will use it
    useproxy=with
else
    useproxy=without
fi

export OSimage REPO useproxy
echo -e "\n\033[1m=====\033[0m Testing installation of \033[1m${BUNDLES[@]}\033[0m on \033[1m${OSimages[@]}\033[0m using \033[1m$REPO\033[0m repository \033[1m=====\033[0m\n"
$debug && echo -e "\033[1m\033[5;33mDEBUG mode on\033[0m\n"
# And cleanup before testing
mkdir -p ${LOGS_PREFIX%%/*}
rm -f ${LOGS_PREFIX}_*.log
docker compose down

# First we build our images and launch containers
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
        docker compose exec install_test_${OSimage%%:*}${OSimage##*:} /usr/local/bin/ps_install_bundle.sh "$BUNDLE" >> ${LOG}.log
        STATUS=$?
        OUTPUT="$BUNDLE install "
        if [ "$STATUS" -eq "0" ]; then
            OUTPUT+="\033[1;32mSUCCEEDED!\033[0m"
        else
            echo -e "\033[0;31m$BUNDLE failed to install with status: $STATUS\033[0m"
            if $debug; then
                echo "Installation script failed, we'll get you a shell…"
                container_debug install_test_${OSimage%%:*}${OSimage##*:}
            else
                echo -e "Check the logs and then enable debug mode (-D) if you want to drop into a shell after the failed install."
            fi
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
        docker compose run single_sanity install_test_${OSimage%%:*}${OSimage##*:} $REPO >> ${LOG}_test.log 2>&1
        SERVICE_STATUS=$?
        # TODO: try to capture output from run
        OUT+="\n"
        #echo -e "OUT:\n$OUT\n"

        OUTPUT="$BUNDLE service checks "
        if [ "$SERVICE_STATUS" -eq "0" ]; then
            OUTPUT+="\033[1;32mRAN OK!\033[0m"
        else
            if $debug; then
                echo "It seems like testing failed, we'll get you a shell to debug further…"
                container_debug install_test_${OSimage%%:*}${OSimage##*:}
            fi
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