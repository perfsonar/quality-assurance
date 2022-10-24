#!/usr/bin/env bash
# To debug a failing install

# Defaults
REPO="perfsonar-release"
OSimage="debian:stretch"
BUNDLE="perfsonar-toolkit"
debug=false

# Parsing options
while getopts "Dh" OPT; do
    case $OPT in
        D) debug=true ; need_shift=true ;;
        h)
            show_help >&2
            exit 1 ;;
    esac
done
shift $((OPTIND))

# Parse CLI args
if [ -n "$1" ]; then
    # Set repo
    REPO="$1"
    if [ -n "$2" ]; then
        # Set OSimage
        OSimage="$2"
        if [ -n "$3" ]; then
            # Set Bundle
            BUNDLE="$3"
        fi
    fi
fi

# State what we'll do
echo -e "\n\033[1m=====\033[0m Testing installation of \033[1m$BUNDLE\033[0m on \033[1m$OSimage\033[0m using \033[1m$REPO\033[0m repository \033[1m=====\033[0m\n"
export OSimage REPO useproxy
if [ -n "$proxy" ]; then
    # If $proxy is set, then we will use it
    useproxy=with
else
    useproxy=without
fi

# Prepare Docker setup
docker compose down
docker-compose build --force-rm
docker rm -f install-single-sanity > /dev/null 2>&1
docker compose up -d

# Try the install
echo -e "\n\033[1m===== Installing =====\033[0m\n"
docker-compose exec --privileged install_test /usr/local/bin/ps_install_bundle.sh "$BUNDLE"
if [ "$?" -ne  "0" ]; then
    # Something failed, we open a shell in the container to diagnose
    echo "Installation script failed, we'll get you a shell…"
    docker cp ./debug-pscheduler-api.sh install-test:/usr/local/bin/
    docker-compose exec --privileged install_test apt-get install -y less vim
    docker-compose exec --privileged install_test bash
else
    # We then try to run the sanity tests
    echo -e "\n\033[1m===== Testing =====\033[0m\n"
    docker run --privileged --name install-single-sanity --rm single-sanity install-test $BUNDLE $REPO
    if [ "$?" -ne  "0" ]; then
        # Something failed, we open a shell in the container to diagnose
        echo "It seems like testing failed, we'll get you a shell to debug further…"
        docker cp ./debug-pscheduler-api.sh install-test:/usr/local/bin/
        docker-compose exec --privileged install_test apt-get install -y less vim
        docker-compose exec --privileged install_test bash
    else
        echo -e "\n\033[32m===== All went fine! =====\033[0m\n"
    fi
fi

# Wrapping up
echo -e "\nNow stopping containers."
docker compose down

