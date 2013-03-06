#!/bin/bash

set -e

CYAN="\033[00;36m"
GREEN="\033[00;32m"
PURPLE="\033[00;35m"
RED="\033[00;31m"
WHITE="\033[00m"
YELLOW="\033[00;33m"

# Make sure script is run with root privileges
if [ ! $UID -eq 0 ] ; then
    echo -e "${RED}Script must be run as root${WHITE}"
    exit
fi

# Disable strict host key checking so user isn't prompted during install
[ ! -d "/root/.ssh" ] && mkdir "/root/.ssh"
echo -e "Host *\n  StrictHostKeyChecking no" > /root/.ssh/config

SCRIPT_LOCATION=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
PUPPET_FILE="${SCRIPT_LOCATION}/Puppetfile"
PUPPET_DIR="/etc/puppet"
MODULE_DIR="${PUPPET_DIR}/modules/lamp"

# Install ruby gems if necessary
if ! "gem" -v $1 >/dev/null 2>&1
then
    echo -e "\n${GREEN}Installing rubygems"
    echo -e "===================${WHITE}"
    apt-get install -y "rubygems"
fi

# Install Augeas support if necessary
if ! "echo -e \"require 'augeas'\nputs Augeas.open\" | ruby -rrubygems" -v $1 >/dev/null 2>&1
then
    echo -e "\n${GREEN}Installing Augeas for Puppet"
    echo -e "=================${WHITE}"
    apt-get update
    apt-get install libaugeas-ruby -y
fi

# Install puppet librarian though rubygems
if ! "librarian-puppet" -v $1 >/dev/null 2>&1
then
    echo -e "\n${GREEN}Installing librarian-puppet"
    echo -e "==========================${WHITE}"
    # The current release (0.9.7 4) of librarian puppet is currently buggy,
    # use a fork with the fix in it instead
    # see: https://github.com/rodjek/librarian-puppet/issues/31

    # gem install "librarian-puppet"
    gem install "librarian-puppet-maestrodev"
fi

# Init puppet modules with puppet librarian
echo -e "\n${GREEN}Installing puppet modules"
echo -e "=========================${WHITE}"
ln -sf "${PUPPET_FILE}" "${PUPPET_DIR}/Puppetfile"
cd "${PUPPET_DIR}"
librarian-puppet install --clean --verbose

# Link build module
if [ ! -L "${MODULE_DIR}" ]; then
    ln -s "${SCRIPT_LOCATION}/../../" "${MODULE_DIR}"
fi

# Run test install
puppet apply "${SCRIPT_LOCATION}/../lamp.pp"
puppet apply "${SCRIPT_LOCATION}/../app.pp"
