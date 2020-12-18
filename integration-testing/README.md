# integration-testing

This project provides ways of performing installation/integration testing on various parts of perfSONAR using virtual environments.

The `docker` parts are much more developed than the `vagrant` pieces. In either case, they should be readily adaptable to test other parts of the perfSONAR ecosystem.

## Overview

The basic idea behind these modules is to create fresh OS environments (container or VM), install the relevant components from scratch, making sure that no errors are encountered in the process. Next, optionally, additional sanity checks are run before tearing down the temporary containers.

The results can just be displayed in a one-off fashion, or they can be stored and stuck into an ELK stack for further processing. The checks can also run via cron to track them over time.

## Docker

The Docker components provide for testing all the CentOS RPM bundle installs in an automated way, for any given perfSONAR repository.

Similarly, you can test installing PWA from RPMs on CentOS.

This can optionally hook into the `sanity-checking` modules to run sanity checks as part of the process.

## Vagrant

The Vagrantfiles provided are intended to work similarly to the Dockerfiles above, but are not as well developed.

### Other examples files

In both the `docker` and `vagrant` folders are folders matching the pattern `Zoriginals-author`; these are some of the original files that were received from other devs, and in some cases adapted. There may be other useful examples in them, so they are included here.
