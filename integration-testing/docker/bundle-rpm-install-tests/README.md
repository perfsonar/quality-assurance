# bundle-rpm-install-tests

This project provides ways of testing installation of perfSONAR RPM package-based bundles on CentOS-based systems using Docker containers.

## Testing perfSONAR installation on CentOS

### OS Support
The Docker testing setup supports the following OS:
 * CentOS 7

### Running the script
The script attempts to install a perfSONAR bundle and then perform sanity checks using the `sanity-checking` scripts.  See [sanity-checking](../../../sanity-checking) for details.

You can run the tests by executing `test_install_instructions.sh -r $REPO -o $OS -b $BUNDLE` (with all args are optional) where (in bold are the defaults):

 * `$REPO` is one of these:
   * **`perfsonar-repo`** (production)
   * `perfsonar-repo-nightly-minor`
   * `perfsonar-repo-nightly-patch`
   * `perfsonar-repo-staging`
 * `$OS` is one of these (default to test **all**):
   * `centos:7`
   * `almalinux:8`
 * `$BUNDLE` is one of these (default to test **all**)
   * `perfsonar-tools`
   * `perfsonar-testpoint`  
   * `perfsonar-archive`  
   * `perfsonar-dashboards`  
   * `perfsonar-core`
   * `perfsonar-centralmanagement`
   * `perfsonar-toolkit`

### Debugging an install
When one of the installation is failing, you can re-run the script with the `-D` option, in case installation is failing, it will then drop into a shell, in the container, to debug further the installation issue faced.  So, something like `./test_install_instructions.sh -r $REPO -o $OS -b $BUNDLE -D`

Once inside this container, you can use the command `debug-pscheduler-api.sh URL` with a path to a pScheduler API object to debug pScheduler behaviour.

## About the Docker images
### Docker daemon configuration

For the Docker images to work with `systemd`, as of Docker Engine 20.10.12 and Docker Desktop 4.4.2 on MacOS, one need to enable the `"cgroup-parent": "docker.slice"` property in the `daemon.json` file. With that setting, no declaration nor mounting of the volume `/sys/fs/cgroup` is needed as previously.

It needs to be confirmed if this setup is working on Docker host system different from MacOS.  See [this discussion for a complete explanation about this change](https://serverfault.com/questions/1053187/systemd-fails-to-run-in-a-docker-container-when-using-cgroupv2-cgroupns-priva).