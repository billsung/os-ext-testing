#! /usr/bin/env bash

# Sets up a log server for Jenkins to save test results to.

set -e

THIS_DIR=`pwd`

# TODO: Either edit the variables here and make sure the values are correct, or
# set them before running this script
: ${LOG_SERVER_DOMAIN:=127.0.0.1}
# No whitespace (i.e. remove "ssh-rsa " identifier and ending comment field)!
: ${JENKINS_SSH_PUBLIC_KEY_CONTENTS:="AAAAB3NzaC1yc2EAAAADAQABAAAAgQCylHqU9YEt3nSMgsUOXh1OeENBh15x8fPfG0rivvkN7kgh0t6JEXGWu/NAHHEYqr5UQ4ul3uKqHgLDtBiEGMa1vtUWZOUYWrdQjEoTNM2SD1ZNDJ7biQoD2wxcpRZ9Y9i4ZQh9rGhOmo3YK53vzxTUApcON39KuefeN5OprCzcKw=="}

OSEXT_PATH=$THIS_DIR/os-ext-testing
OSEXT_REPO=https://github.com/johnnychou/os-ext-testing
PUPPET_MODULE_PATH="--modulepath=$OSEXT_PATH/puppet/modules:/root/system-config/modules:/etc/puppet/modules"

if ! sudo test -d /root/system-config; then
  sudo git clone https://review.openstack.org/p/openstack-infra/system-config.git \
    /root/system-config
fi

if ! sudo test -d /root/project-config; then
  sudo git clone https://github.com/openstack-infra/project-config.git \
    /root/project-config
fi

# Install Puppet and the OpenStack Infra Config source tree
# TODO(Ramy) Make sure sudo has http proxy settings...
if [[ ! -e install_puppet.sh ]]; then
  wget https://git.openstack.org/cgit/openstack-infra/system-config/plain/install_puppet.sh
  sudo bash -xe install_puppet.sh
  sudo /bin/bash /root/system-config/install_modules.sh
fi

# Update /root/system-config
echo "Update system-config"
sudo git  --work-tree=/root/system-config/ --git-dir=/root/system-config/.git remote update
sudo git  --work-tree=/root/system-config/ --git-dir=/root/system-config/.git pull

echo "Update project-config"
sudo git  --work-tree=/root/project-config/ --git-dir=/root/project-config/.git remote update
sudo git  --work-tree=/root/project-config/ --git-dir=/root/project-config/.git pull

# Clone or pull the the os-ext-testing repository
if [[ ! -d $OSEXT_PATH ]]; then
    echo "Cloning os-ext-testing repo..."
    git clone $OSEXT_REPO $OSEXT_PATH
fi

if [[ "$PULL_LATEST_OSEXT_REPO" == "1" ]]; then
    echo "Pulling latest os-ext-testing repo master..."
    cd $OSEXT_PATH; git checkout master && sudo git pull; cd $THIS_DIR
fi

CLASS_ARGS="domain => '$LOG_SERVER_DOMAIN', "
CLASS_ARGS="$CLASS_ARGS jenkins_ssh_key => '$JENKINS_SSH_PUBLIC_KEY_CONTENTS', "

sudo puppet apply --verbose $PUPPET_MODULE_PATH -e "class {'logging::master': $CLASS_ARGS }"
