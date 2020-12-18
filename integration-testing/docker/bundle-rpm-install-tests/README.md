# bundle-rpm-install-tests

This project provides ways of testing installation of  CentOS RPM bundles using Docker containers.

It attempts to perform sanity checks using the `sanity-checking` scripts (so those will need to be built with Docker first). See `../../sanity-checking`.

The repo it uses is configurable.

You can run the tests by executing ($REPO is optional) `test_install_instructions.sh $REPO`

Where `$REPO` is one of these (default is to use production):
 * `staging`
 * `nightly-minor`
 * `nightly-patch`
