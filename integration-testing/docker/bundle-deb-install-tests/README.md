# bundle-deb-install-tests

This project provides ways of testing installation of perfSONAR DEB package-based bundles on Debian-based systems using Docker containers.

## Testing perfSONAR installation on Debian and Ubuntu

### OS Support
Fully Supported:
 * Debian 9 Stretch
 * Ubuntu 16 Xenial Xerus
 * Ubuntu 18 Bionic Beaver

Partial support:
 * Debian 10 Buster (only `perfsonar-testpoint` bundle)
 * Ubuntu 20 Focal (only 

### Running the script
The script attempts to perform sanity checks using the `sanity-checking` scripts (so those will need to be built with Docker first). See `../../sanity-checking`.

You can run the tests by executing `test_install_instructions.sh $REPO $OS $BUNDLE` (with all args optional but the previous one always required) where:

 * `$REPO` is one of these (default is to use production):
 ** `perfsonar-release` (production)
 ** `perfsonar-patch-snapshot`
 ** `perfsonar-minor-snapshot`
 ** `perfsonar-patch-staging`
 * `$OS` is one of these (default to test all):
 ** `debian:stretch`
 ** `debian:buster`
 ** `ubuntu:xenial`
 ** `ubuntu:bionic`
 * `$BUNDLE` is one of these (default is to test all)
 ** `perfsonar-tools`
 ** `perfsonar-testpoint`
 ** `perfsonar-core`
 ** `perfsonar-centralmanagement`
 ** `perfsonar-toolkit`

### Debugging an install
When one of the installation is failing, you can use a dedicated debug script to re-run the installation and drop into a shell, in the container, to debug further the installation issue faced.  This is done with `debug_install.sh $REPO $OS $BUNDLE`

Once inside this container, you can use the command `debug-pscheduler-api.sh URL` with a path to a pScheduler API object to debug pScheduler behaviour.

### Using a proxy to speed packages download
If you want to use an HTTP/HTTPS proxy to speed up downloading of packages for the different images and to run the install tests (so both at Docker build and run time), you can do it this way: `useproxy=yes proxy=172.17.0.1:3128 ./test_install_instructions.sh $REPO $OS $BUNDLE`  The given proxy variable will be used to set both `$http_proxy` and `$https_proxy` and making `$no_proxy` set to `localhost,127.0.0.1` so that pScheduler calls don't get passed through the proxy.

And that's the same with the `debug_install` script, it takes the same ENV variables.

## About the Docker images

### Docker daemon configuration

For the Docker images to work with `systemd`, as of Docker Engine 20.10.12 and Docker Desktop 4.4.2 on MacOS, one need to enable the `"cgroup-parent": "docker.slice"` property in the `daemon.json` file. With that setting, no declaration nor mounting of the volume `/sys/fs/cgroup` is needed as previously.

It needs to be confirmed if this setup is working on Docker host system different from MacOS.  See [this discussion for a complete explanation about this change](https://serverfault.com/questions/1053187/systemd-fails-to-run-in-a-docker-container-when-using-cgroupv2-cgroupns-priva).
