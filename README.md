# Quality Assurance

Automated/virtualized quality assurance tools; system integration testing, service sanity checks

This includes these components:

1. Integration test tools - Automated testing of bundle installs, upgrades, etc - virtualized  (docker/vagrant)
1. Sanity Checking - sanity checking for QA testing. Checks that services are running/available, webservices are correctly loading/responding, expected ports are open, etc.
  * Run on demand or automated
  * Includes a dockerized ELK environment for archiving/visualizing results
1. pScheduler Crawler - for a given psconfig, probes pscheduler's internal states on all the hosts and archives the results for later analysis
  * Includes ELK config info
