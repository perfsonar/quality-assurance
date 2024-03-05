#!/bin/bash

# Remount /tmp allowing exec
mount /tmp -o remount,exec

# Remove custom Docker policy-rc.d if present
sed -i 's/^exit 101//' /usr/sbin/policy-rc.d

# Let's be up to date
apt-get update

BUNDLE="$@"
OS=`awk -F '"' '/PRETTY_NAME/ {print $2}' /etc/os-release`

# First download packages using the proxy if there is one
apt-get -d install -y $BUNDLE
echo -e "\n\033[1;32mFinished downloading packages to install $BUNDLE on $OS\033[0m\n"

# Make sure a HTTPS proxy isn't used as it breaks OpenSearch installation
unset https_proxy
apt-get install -y $BUNDLE
if [ "$?" -ne "0" ]; then
    echo -e "\n\033[1;33mSomething went wrong during installation\033[0m\n"
    echo "Let's try installing a second time." >&2
fi
apt-get install -y $BUNDLE
if [ "$?" -ne "0" ]; then
    echo -e "\n\033[1;31mSomething went wrong during installation\033[0m\n"
    exit 1
fi
echo -e "\n\033[1;32mInstallation of bundle $BUNDLE on $OS went fine!\033[0m\n"

if [[ $BUNDLE =~ perfsonar-(core|testpoint|toolkit) ]]; then
    # Run pscheduler to see if all is fine
    echo "We'll now try to run pscheduler…"
    # Wait a bit so that pScheduler is ready
    sleep 15
    pscheduler troubleshoot
    if [ "$?" -ne "0" ]; then
        # Try a second time as pScheduler might be a bit picky
        sleep 30
        pscheduler troubleshoot
        if [ "$?" -ne "0" ]; then
            # Try a third and last time!
            sleep 60
            pscheduler troubleshoot
            if [ "$?" -ne "0" ]; then
                echo -e "\n\033[1;31mSomething went wrong with pScheduler\033[0m\n"
                exit 1
            fi
        fi
    fi

    echo -e "\npScheduler seems to be running fine!\n"
fi

