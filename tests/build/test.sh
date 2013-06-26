#!/bin/bash

# Current Directory
SCRIPT_LOCATION=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Expected install manifest location
INSTALL_MANIFEST="${SCRIPT_LOCATION}/../app.pp"

# Expected Puppetfile location
PUPPET_FILE="${SCRIPT_LOCATION}/Puppetfile"

# Where to install puppet to
PUPPET_DIR="/etc/puppet"

# The version of puppet to use
PUPPET_VERSION="3.2.2"

# The version of librarian puppet to use
LIBRARIAN_PUPPET_VERSION="0.9.9"

# THe name of your application module, this should be a directory in ${SCRIPT_LOCATION}
APP_MODULE="lamp"

APP_SOURCE_DIRECTORY="${SCRIPT_LOCATION}/../.."

######################## No need to change anything below here #############################

# So execution stops on error
set -e

# Colorful output
CYAN="\033[00;36m"
GREEN="\033[00;32m"
PURPLE="\033[00;35m"
RED="\033[00;31m"
WHITE="\033[00m"
YELLOW="\033[00;33m"

# Default environment for symfony calls
ENV="prod"

# Flag so we don't call apt-update more than once
APT_UPDATED=false

# Weather or not we should clean previously installed puppet modules (-c enables this)
CLEAN_PUPPET_MODULES=false

# Function to test for package existence
ensure_package () {
	if ! command -v $1 >/dev/null 2>&1; then
        echo -e >&2 "${RED}Setup could not find required ${GREEN}\"${1}\"${RED} command"
        echo -e >&2 "Install ${GREEN}\"${1}\"${RED} and/or add to your PATH and try again${WHITE}";
        exit 1
    fi
}

ensure_root () {
    # Make sure script is run with root privileges
    if [ ! $UID -eq 0 ] ; then
        echo -e "${RED}Script must be run as root${WHITE}"
        exit 2
    fi
}

# Disable strict host key checking so user isn't prompted during install
disable_strict_host_check () {
    [ ! -d "/root/.ssh" ] && mkdir "/root/.ssh"
    echo -e "Host *\n  StrictHostKeyChecking no" > /root/.ssh/config
}

# Make sure the puppet config manifest is present
verify_install_manifest () {
    if [ ! -f ${INSTALL_MANIFEST} ]
    then
        echo -e "\
${RED}Could not find ${INSTALL_MANIFEST}. Copy install.pp.dist to ${INSTALL_MANIFEST} \
and run again from the source root.${WHITE}"
        exit 2
    fi
}

# So apt-get update is only run once
apt_update () {
    if ! ${APT_UPDATED}; then
        echo -e "\n${GREEN}Updating Apt Repositories"
        echo -e "===================${WHITE}"
        apt-get update
        APT_UPDATED=true
    fi
}

install_ruby_gems () {
    if ! gem -v $1 >/dev/null 2>&1; then
        apt_update
        echo -e "\n${GREEN}Installing rubygems"
        echo -e "===================${WHITE}"
        apt-get install -y "rubygems"
    fi
}

remove_gem () {
    GEM_NAME=${1}
    echo -e "\n${GREEN}Removing Previous \"${GEM_NAME}\" Install"
    echo -e "(${YELLOW}If prompted, remove executables${GREEN})"
    echo -e "================================${WHITE}"
    gem uninstall --all --ignore-dependencies ${GEM_NAME}
}

install_puppet () {
    if ! gem list | grep -qi "puppet (${PUPPET_VERSION})"; then
        if gem list | grep -qi puppet; then
            remove_gem "puppet"
        fi
        echo -e "\n${GREEN}Installing Puppet V${PUPPET_VERSION}"
        echo -e "========================${WHITE}"
        gem install puppet -v "=${PUPPET_VERSION}" --no-rdoc --no-ri
    fi
}

install_librarian_puppet () {
    if gem list | grep -qi librarian-puppet-maestrodev; then
        remove_gem "librarian-puppet-maestrodev"
    fi
    if ! gem list | grep -qi "librarian-puppet (${LIBRARIAN_PUPPET_VERSION})"; then
        if gem list | grep -qi librarian-puppet; then
            remove_gem "librarian-puppet"
        fi
        echo -e "\n${GREEN}Installing Librarian-Puppet V${LIBRARIAN_PUPPET_VERSION}"
        echo -e "==================================${WHITE}"
        gem install librarian-puppet -v "=${LIBRARIAN_PUPPET_VERSION}" --no-rdoc --no-ri
    fi
}

install_puppet_modules () {
    echo -e "\n${GREEN}Installing puppet modules"
    echo -e "=========================${WHITE}"
    ln -sf "${PUPPET_FILE}" "${PUPPET_DIR}/Puppetfile"

    cd "${PUPPET_DIR}"

    if ${CLEAN_PUPPET_MODULES}; then
        echo -e "${YELLOW}Clearing puppet module cache before librarian install${WHITE}"
        librarian-puppet install --clean
    else
        echo -e "${YELLOW}Pass \"-c|--clean-puppet-modules\" to clear the module cache${WHITE}"
        librarian-puppet install
    fi

    APP_MODULE_INSTALL_LOC="/etc/puppet/modules/${APP_MODULE}"
    if ! [ -d ${APP_MODULE_INSTALL_LOC} ]; then
        ln -s "${APP_SOURCE_DIRECTORY}" ${APP_MODULE_INSTALL_LOC}
    fi

    echo -e "${GREEN}Librarian install complete${WHITE}"

    cd "${SCRIPT_LOCATION}"
}

# Install app with install manifest
apply_puppet_manifest () {
    echo -e "\n${GREEN}Provisioning server according to Puppet manifest"
    echo -e "================================================${WHITE}"
    puppet apply "${INSTALL_MANIFEST}"
}

# Make sure getopt is present
ensure_package "getopt"

# Execute getopt on the arguments passed to this program, identified by the
# special character $@
SHORTOPTS="e:c"
LONGOPTS="env:clean-puppet-modules"
PARSED_OPTIONS=$(getopt -n "${0}" -o ${SHORTOPTS} -l ${LONGOPTS} -- "$@" )

#Bad arguments, something has gone wrong with the getopt command.
if [ $? -ne 0 ];
then
  exit 1
fi

# Setting options to input variables
eval set -- "${PARSED_OPTIONS}"

# Go through options with a case and using shift to analyse 1 argument at
# a time. $1 identifies the first argument, shift discards $1 and $2 becomes
# the new $1 after which we precede through the case.
while true;
do
  case "$1" in

    -e|--env)
        ENV="${2}"
        shift
        shift;;

    -c|--clean-puppet-modules)
        CLEAN_PUPPET_MODULES=true
        shift;;

    --)
      shift
      break;;

  esac
done

ensure_root
verify_install_manifest
disable_strict_host_check
install_ruby_gems
install_puppet
install_librarian_puppet
install_puppet_modules
apply_puppet_manifest

