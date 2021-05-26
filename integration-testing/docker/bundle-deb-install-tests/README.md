# bundle-deb-install-tests

This project provides ways of testing installation of perfSONAR DEB package-based bundles on Debian-based systems using Docker containers.

### OS Support
Fully Supported:
 * Debian 9 Stretch
 * Ubuntu 16 Xenial Xerus
 * Ubuntu 18 Bionic Beaver

Partial support:
 * Debian 10 Buster (only `perfsonar-testpoint` bundle)

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

### Using a proxy to speed packages download
If you want to use an HTTP/HTTPS proxy to speed up downloading of packages for the different images and to run the install tests (so both at Docker build and run time), you can do it this way: `useproxy=yes proxy=172.17.0.1:3128 ./test_install_instructions.sh $REPO $OS $BUNDLE`  The given proxy variable will be used to set both `$http_proxy` and `$https_proxy` and making `$no_proxy` set to `localhost,127.0.0.1` so that pScheduler calls don't get passed through the proxy.

