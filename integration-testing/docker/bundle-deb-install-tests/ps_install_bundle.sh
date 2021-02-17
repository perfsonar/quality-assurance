#!/bin/bash

# Remount /tmp allowing exec
mount /tmp -o remount,exec

apt-get update

BUNDLE=$1
apt-get install -y $BUNDLE
if [ "$?" -ne "0" ]; then
    echo -e "\nSomething went wrong during installation\n"
    exit 1
fi

echo -e "\nInstallation of bundle $BUNDLE went fine!\n"

if [[ $BUNDLE =~ perfsonar-(core|testpoint|toolkit) ]]; then
    # Run pscheduler to see if all is fine
    echo "We'll now try to run pscheduler…"
    # Wait a bit so that pScheduler is ready
    sleep 60
    pscheduler troubleshoot
    if [ "$?" -ne "0" ]; then
        # Try a second time as pScheduler might be a bit picky
        pscheduler troubleshoot
        if [ "$?" -ne "0" ]; then
            echo -e "\nSomething went wrong with pScheduler\n"
            exit 1
        fi
    fi

    echo -e "\npScheduler seems to be running fine!\n"
fi

