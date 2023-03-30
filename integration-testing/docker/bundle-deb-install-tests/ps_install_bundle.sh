#!/bin/bash

# Remount /tmp allowing exec
mount /tmp -o remount,exec

apt-get update

BUNDLE=$1
apt-get install -y $BUNDLE
if [ "$?" -ne "0" ]; then
    echo -e "\n\033[1;31mSomething went wrong during installation\033[0m\n"
    exit 1
fi

OS=`awk -F '"' '/PRETTY_NAME/ {print $2}' /etc/os-release`
echo -e "\n\033[1;32mInstallation of bundle $BUNDLE on $OS went fine!\033[0m\n"

if [[ $BUNDLE =~ perfsonar-(core|testpoint|toolkit) ]]; then
    # Run pscheduler to see if all is fine
    echo "We'll now try to run pscheduler…"
    # Wait a bit so that pScheduler is ready
    sleep 50
    # We don't want to have any https proxy in the way
    unset https_proxy
    pscheduler troubleshoot
    if [ "$?" -ne "0" ]; then
        # Try a second time as pScheduler might be a bit picky
        sleep 25
        pscheduler troubleshoot
        if [ "$?" -ne "0" ]; then
            # Try a third and last time!
            sleep 15
            pscheduler troubleshoot
            if [ "$?" -ne "0" ]; then
                echo -e "\n\033[1;31mSomething went wrong with pScheduler\033[0m\n"
                exit 1
            fi
        fi
    fi

    echo -e "\npScheduler seems to be running fine!\n"
fi

