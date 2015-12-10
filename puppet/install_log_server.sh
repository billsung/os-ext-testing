#! /usr/bin/env bash

# Sets up a log server for Jenkins to save test results to.

set -e


# TODO: Either edit the variables here and make sure the values are correct, or
# set them before running this script
: ${DOMAIN:=127.0.0.1}
: ${JENKINS_SSH_PUBLIC_KEY:="AAAAB3NzaC1yc2EAAAADAQABAAAAgQCylHqU9YEt3nSMgsUOXh1OeENBh15x8fPfG0rivvkN7kgh0t6JEXGWu/NAHHEYqr5UQ4ul3uKqHgLDtBiEGMa1vtUWZOUYWrdQjEoTNM2SD1ZNDJ7biQoD2wxcpRZ9Y9i4ZQh9rGhOmo3YK53vzxTUApcON39KuefeN5OprCzcKw=="}

PUPPET_MODULE_PATH="--modulepath=/etc/puppet/modules"

# Install Puppet
if [[ ! -e install_puppet.sh ]]; then
  wget https://git.openstack.org/cgit/openstack-infra/system-config/plain/install_puppet.sh
  sudo bash -xe install_puppet.sh
  sudo git clone https://review.openstack.org/p/openstack-infra/system-config.git \
    /root/system-config
  sudo /bin/bash /root/system-config/install_modules.sh
fi

CLASS_ARGS="domain => '$DOMAIN',
            jenkins_ssh_key => '$JENKINS_SSH_PUBLIC_KEY', "

set +e
sudo puppet apply --test $PUPPET_MODULE_PATH -e "class {'openstackci::logserver': $CLASS_ARGS }"
PUPPET_RET_CODE=$?
# Puppet doesn't properly return exit codes. Check here the values that
# indicate failure of some sort happened. 0 and 2 indicate success.
if [ "$PUPPET_RET_CODE" -eq "4" ] || [ "$PUPPET_RET_CODE" -eq "6" ] ; then
    echo "Puppet failed to apply the log server configuration."
    exit $PUPPET_RET_CODE
fi
set -e

exit 0
