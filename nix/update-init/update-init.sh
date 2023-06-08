#! /bin/bash
#
# @brief:     simple script for initiate unattended update process
# @author:    Gregor A. Segner
# @license:   BSD-3-Clause https://opensource.org/license/bsd-3-clause/
# @copyright: 2023 - Gregor A. Segner
# @url:       https://gist.github.com/g4s/556a61db427e1a6592934288728270dd
#
# last update: 2023-06-06
#
# @description:
#  This script has the intend to initiate unattended update 
#  processes on various *nix platforms.
#  During execution there are two main options: updates/upgrades
#  with the help of system package-managern (and pip) or the
#  more powerfull option: ansible-pull.
#
#  If ansible-pull will be the prefered option, the best option
#  would be, the set an environment variable $playbook which
#  contains a git-repo-url. This is the most flexible option.
#  Also it is possible to configure a fallback repo inside this
#  script.
#
#  If ansible will not be used, the script will try to use
#  a system package manager.
#
#  After trying to update the system, the script will also try
#  to install python packages with pip.
#
#  One special thing is macOS: here the script tries to update
#  also app-store apps.

#set -o errexit     # exit when single command produce error
#set -o nounset     # exit when using undeclared vars
#set -o xtrace      # see debugging races - uncomment or using

## @ToDo implement logging
## @ToDo implement Solaris support
## @ToDo implement maintenance mode --> testing

## configuration vars
#
apprise="/usr/local/bin/apprise"

# potkey and potoken are necessary, if you wish to push status
# updates over pushover.
pokey=""
potoken=""

waitforupdate="60"

## functions
#
pushNotify () {
  if [[ -f "{apprise}" ]]; then
    if ! [[ -z  "${pokey}" ]] && ! [[ -z "${potoken}" ]]; then
      ${apprise} -t "${1}" -b "${2}" pover://"${pokey}"@"${potoken}"
    else
      echo "could not find API-keys for pushover"
    fi
  fi
}


# check env for playbook var - if not set you can define here the 
# playbook-URL
if [[ -z "${playbook}" ]]; then
  playbook=""
fi

pushNotify "Network Maintenance Notification" "initiate update process on $(hostname --fqdn)"
echo "initiate update process on $(hostname --fqdn)"

# inform users in shell sessions
if [[ $(who | cut -f1 -d ' ' | sort -u | wc -l) -gt 0 ]]; then
  wall -n "Attention! Dear user this system will initiate an updated proces in ${waitforupdate} seconds."
  echo "inform logined users... wait ${waitforupdate} seconds."
  sleep ${waitforupdate}
fi

if [ -z "${playbook}" ]; then
  echo "no ansible playbook provided: will update with package management"
  
  ##
  # This script can call various package manager on unix and linux systems.
  # At first we try to detect os-family. In the next step we want select the
  # package manager (or a combinatione of various package manager).
  
  case $(uname) in
    Linux)
      echo "detected Linux system..."

      # create timeshift restore point if possible
      if command -v timeshift; then
        echo "creating restore point..."
        timeshift --create --comments "pre update restorpoint [$(date +\"%Y5m%d\")]" --tags O --scripted
        if [[ $? -eq 0 ]]; then
          echo "created restore-point"
          pushNotify "$(hostname --fqdn)" "created succesfull system resore-point"
        fi
      else
        echo "could not create restorepoint - timeshift could not be found on system"
      fi

      if command -v dnf; then
        dnf update -y
      elif command -v apt-get; then
        apt-get update
        apt-get upgrade -y
      elif command -v yay; then
        sudo -K    # drop privileges, cause yay run in trouble with elevated rights
        yay -Syu
      else
        echo "Sorry, but script can not initiate update process on machine $(hostname)"
      fi

      # update snaps if system used them
      ## ATTENTION: untested command sequenze
      if command -v snapd; then
        echo "found snapd - will also update snaps"
        $(command -v snap) refresh
      fi
      ;;
    FreeBSD)
      echo "detected FreeBSD system..."
      freebsd-update fetch && frebsd-update install
      
      echo "finished system upgrade - continue with 3rd party software"
      pkg upgrade
      portsnap auto
      ;;
    Darwin)
      echo "detected macOS system..."
      echo "updating packages with homebrew..."
      brew update && brew upgrade
      
      if command -v mas; then
        echo "trying to update appstore apps with mas-cli..."
        mas upgrade
      else
        echo "[Warning] - could not update appstore apps: could not find mas-cli"
      fi
      ;;
  esac
  
  # updating global installed python packages
  if command -v pip; then
    echo "updating global installed python packages with pip"
    pip list -o | cut -f1 -d' ' | tr " " "\n" | awk '{if(NR>=3)print}' | cut -d' ' -f1 | xargs -n1 pip install -U
  else
    python -m pip --version 2>&1 > /dev/null
    if [[ ${?} -eq 0 ]]; then 
      python -m pip list -o | cut -f1 -d ' '| tr ' ' '\n' | awk '{if(NR>=3)print}' | cut -d ' ' -f1 | xargs -n1 python -m pip install -U
    else
      echo "[Warning] could not find pip - will not update global python package index"
    fi  
  fi
  
  # check if services or machine must be restarted
  # helpertool - https://github.com/liske/needresart
  if command -v needrestart; then
    echo "check if system and services need restart..."
    needrestart -m a
  else
    echo "[Warning] could not check if system need restart - could not find helper"
    echo "[Warning] check out https://github.com/liske/needrestart"
  fi
else
  echo "playbook url provided - initiate maintenance with ansible"
  if command -v ansible-pull; then
    # check if playbook is already fetched and if there exists a gilt.yml
    if [ -f "/opt/provisioning/gilt.yml" ]; then
      cd /opt/provisioning
      gilt overlay
    fi
    
    # fetch ansible playbook and execute
    ansible-pull -d /opt/provisioning -f -U ${playbook} --full -i localhost

    if [[ $(command -v needrestart) ]]; then
        echo "check if system and services need restart..."
	$(command -v needrestart) -m a
    else
        echo "[Warning] could not check, if system needs restart - could not find helper"
        echo "[Warning] check out https://github.com/liske/needrestart"
    fi
  fi
fi