# bundle
This project provides ways of testing installation of perfSONAR DEB and RPM package-based bundles on Debian-based systems and Almalinux using Docker containers.

## Testing perfSONAR installation

### OS Support
The Docker testing setup supports the following OS:
 * Debian 10 Buster
 * Debian 11 Bullseye
 * Ubuntu 18 Bionic Beaver
 * Ubuntu 20 Focal Fossa
 * Ubuntu 22 Jammy Jellyfish
 * Almalinux 9
 * Rockylinux 9

### Running the script
The script attempts to install a perfSONAR bundle and then perform sanity checks using the `sanity-checking` scripts.  See [sanity-checking](../../../sanity-checking) for details.

You can run the tests by executing `test_install_instructions.sh -r $REPO -o $OS -b $BUNDLE` (with all args are optional) where (in bold are the defaults):

 * `$REPO` is one of these:
   * **`perfsonar-release`** (production)
   * `perfsonar-patch-snapshot`
   * `perfsonar-minor-snapshot`
   * `perfsonar-patch-staging`
 * `$OS` is one of these (default to test **all**):
   * `debian:buster`
   * `debian:bullseye`
   * `ubuntu:bionic`
   * `ubuntu:focal`
   * `ubuntu:jammy`
   * `almalinux:9`
   * `rockylinux:blueonyx`
 * `$BUNDLE` is one of these (default is tools an testpoint as only those are supported on Debian and Ubuntu at the moment)
   * **`perfsonar-tools`**
   * **`perfsonar-testpoint`**
   * `perfsonar-core`
   * `perfsonar-centralmanagement`
   * `perfsonar-toolkit`

### Debugging an install
When one of the installation is failing, you can re-run the script with the `-D` option, in case installation is failing, it will then drop into a shell, in the container, to debug further the installation issue faced.  So, something like `./test_install_instructions.sh -r $REPO -o $OS -b $BUNDLE -D`

Once inside this container, you can use the command `debug-pscheduler-api.sh URL` with a path to a pScheduler API object to debug pScheduler behaviour.

### Using a proxy to speed packages download
If you want to use an HTTP/HTTPS proxy to speed up downloading of packages for the different images and to run the install tests (so both at Docker build and run time), you can do it this way: `proxy=proxy.hostname.tld:3128 ./test_install_instructions.sh -r $REPO -o $OS -b $BUNDLE`  The given proxy variable will be used to set both `$http_proxy` and `$https_proxy` and making `$no_proxy` set to `localhost,127.0.0.1` so that pScheduler calls don't get passed through the proxy.

Look at https://hub.docker.com/r/ubuntu/squid if you want to run a Squid proxy in a container.  You can, for example, launch it with `docker run -d --name squid-proxy --restart always --network bridge -p 3128:3128 -v /Users/Shared/squid:/var/spool/squid -v /Users/Shared/squid/squid.conf:/etc/squid/squid.conf ubuntu/squid:4.10-20.04_beta` and then use `proxy=host.docker.internal:3128` when calling the testing script.

## About the Docker images
### Docker daemon configuration

For the Docker images to work with `systemd`, as of Docker Engine 20.10.12 and Docker Desktop 4.4.2 on MacOS, one need to enable the `"cgroup-parent": "docker.slice"` property in the `daemon.json` file. With that setting, no declaration nor mounting of the volume `/sys/fs/cgroup` is needed as previously.

It needs to be confirmed if this setup is working on Docker host system different from MacOS.  See [this discussion for a complete explanation about this change](https://serverfault.com/questions/1053187/systemd-fails-to-run-in-a-docker-container-when-using-cgroupv2-cgroupns-priva).
