# bundle-deb-install-tests

## TODO
- [ ] add parameter for base OS

This project provides ways of testing installation of  perfSONAR DEB package-based bundles on Debian-based systems using Docker containers.

Fully Supported as of 02/04/2021
 * Debian 9 Stretch
 * Ubuntu 16 Xenial Xerus
 * Ubuntu 18 Bionic Beaver

Partial support:
 * Debian 10 Buster (only `perfsonar-testpoint` bundle)

The script attempts to perform sanity checks using the `sanity-checking` scripts (so those will need to be built with Docker first). See `../../sanity-checking`.

You can run the tests by executing ($REPO is optional) `test_install_instructions.sh $REPO`

Where `$REPO` is one of these (default is to use production):
 * `perfsonar-release`
 * `perfsonar-patch-snapshot`
 * `perfsonar-minor-snapshot`
 * `perfsonar-patch-staging`
