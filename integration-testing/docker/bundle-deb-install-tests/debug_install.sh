#!/usr/bin/env bash
# To debug a failing install

# Defaults
REPO="perfsonar-release"
OSimage="debian:stretch"
BUNDLE="perfsonar-toolkit"

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
export OSimage REPO

# Prepare Docker setup
docker compose down
docker-compose build --force-rm install_test
docker rm -f install-single-sanity
docker compose up -d

# Try the install
echo -e "\n\033[1m===== Installing =====\033[0m\n"
docker-compose exec --privileged install_test /usr/bin/ps_install_bundle.sh "$BUNDLE"
if [ "$?" -ne  "0" ]; then
    # Something failed, we open a shell in the container to diagnose
    echo "Installation script failed, we'll get you a shell…"
    docker-compose exec --privileged install_test bash
else
    # We then try to run the sanity tests
    echo -e "\n\033[1m===== Testing =====\033[0m\n"
    docker run --privileged --name install-single-sanity --network bundle_testing --rm single-sanity install-test $BUNDLE $REPO
    if [ "$?" -ne  "0" ]; then
        # Something failed, we open a shell in the container to diagnose
        echo "Testing failed, we'll get you a shell…"
        docker-compose exec --privileged install_test bash
    else
        echo -e "\n\033[32m===== All went fine! =====\033[0m\n"
    fi
fi

# Wrapping up
echo -e "\nNow stopping containers."
docker compose down

