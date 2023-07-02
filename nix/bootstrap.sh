#! /usr/bin/env bash
# shellcheck disable=
#
# -----
# @brief     : script for initiating bootstrapping on linux hosts
# @author    : Gregor A. Segner
# @license   : BSD-3-clause (  --> https://opensource.org/license/bsd-3-clause )
#
# @plattform : *nix
# @repo      : https://github.com/g4s/collecction
# @issues    : https://github.com/g4s/collecction/issues
#
# version    : development
#
# @copyright : 2023 - Gregor A. Segner 
# 
# last modification: 2023-06-28
# -----
# This is a simple but powerful pre-bootstripping script, that
# ensures everything is set, for bootstripping a linux host.
#
# The simplest option for invoking this script is via curl directly from
# the repo:
#	curl -s -L https://bit.ly/g4s3-bootstrap-nix | bash
#
# This will download the script and piping it to bash
# -----

#####
# global vars
#####
playbook = "https://bit.ly/g4s3-bootstrap-playbook"

function checkCommand () {
	return command -v $1
}


function checkDistri () {
	if [[ checkCommand "hostnamectl" ]]; then
		distri = $(hostnamectl | grep "Operating System" | cut -d ':' -f2 | cut -d ' ' -f2)

		case $distri in
			AlmaLinux)
				echo "RedHat"
				;;
			*)
				echo "unknown"
				;;		
		esac
	fi
}


function makeRestorePoint () {
	checkRootFS () {
		echo $(mount | cut -d ' ' -f3,5 | grep -w '/' | cut -d ' ' -f 2)
	}

	getDataset () {
		echo $(mount | cut -d ' ' -f1,3 | grep -w ${1} | cut -d ' ' -f1)
	}

	if [[ $(checkRootFS) == "zfs" ]]; then
		echo "making zfs-snapshot of /"
		zfs snapshot $(getDataset "/")@pre-provisioning
	else
		if [[ $(checkCommand "timeshift") ]] {
			echo "create system restore-point with timeshift"
			timeshfift --create \
				--comments "pre provisioning restore-point [$(date +\'%Y5m%d\')]" \
				--tags 0 \
				--scripted
		else
			echo "could not create system resore-point"
		}
	fi
}


function updateSystem () {
	echo "updateing system to latest version..."
	case $1 for in
		Redhat)
			dnf update -y
			;;
		Debian)
			apt-get update -y
			apt-get upgrade -y
			;;
		Arch)
			pacman -Syuu
			;;
	esac
}


function installPackage () {
	echo "installing " + $2

	case $1 in
		RedHat)
			dnf install -y $2
			;;
	esac
}


function fetchPlaybook () {
	echo "fetching ansible playbook and store under /tmp/bootstrap/"
	mkdir -P /tmp/bootstrap
	curl -s -L ${playbook} -o /tmp/bootstrap/bootstrap.yml
}


function invokePlaybook () {
	cd /tmp/bootstrap
	ansible-playbook --connction=local \
		--inventory localhost 127.0.0.1 \
		bootstrap.yml \
		--tags="${1}" \
		--extra-vars="${2}"
}


function configureHostname () {
	hostname=
	while [[ $hostname = "" ]]; do
		read -p "please enter the FQDN of the host: " hostname
	done

	echo ${hostname}
}


function configureMaintainUser () {
	username=
	password1=
	password2="blank"
	rtpassword=

	while [[ ${username} == "" ]]; do
		read -p "enter maintaining username: " username
	done

	while [[ ${password2} == "blank" ]]; do
		while [[ ${password1} == "" ]]; do
			read -sp "enter password for user: " password1
		done
		read -sp "re-enter password: " password2

		if [[ ${password1} -eq ${password2} ]]; then
			rtpassword=$(echo ${password1} | sha512sum)
		fi
	done

	echo ${username} + " " + ${rtpassword}
}


function configureTailscale () {
	# @ToDo implement function
}


function configureRport () {
	# @ToDo implement function
}


function configureCockpit () {
	enable=

	while [[ ${enable} == "" ]] or [[ ! ${enable} =~ ^(yes|no)$ ]]; then
		read -p 'do you want to install cockpit: [yes|no] ' enable
	done

	if [[ ${enable} ]]; then
		# @ToDo implement logic
		echo "enabled"
	else
		echo "disabled"
	fi
}


function configureSSH () {
	# @ToDo implent logic
	# we want to install:
	# - OpenSSH
	# - endlessh
	# - sslh
	# - mosh
	# - configure fail2ban for SSH
	# - removing root-login
	# - enable LDAP-login if we bind host to LDAP
}


function configueFusionInventory () {
	# @ToDo implement logic
}


####################
# Will configure playbook environment for installing nsclient++
#
# Globals:
#     none
#
# Aguments:
#     none
#
# Outputs:
#     (string) config - configuration string which represents the env
#
# Returns:
#     0 - on success
####################
function configureNSClient () {
    # @ToDo implement logic
}

####################
# will configure playbook environment, if /etc/motd should be modiied
#
# Globals:
#     none
#
# Aguments:
#     none
#
# Outputs:
#     (string) config - configuration string whch represents the env
#
# Returns:
#     0 - on success
####################
function configureMOTD () {
    # @ToDo implement logic
}


function main () {
	target = $(checkDistri)

	makeRestorePoint
	updateSystem ${target}

	# activating EPEL on RedHat based distris
	if [[ $target == 'RedHat' ]]; then
		echo "enable EPEL and update package cache"
		dnf config-manager --set-enabled crb
		dnf install -y epel-release
		dnf makecache

	# installing ansible and dependencies
	packages = ["python3-pip", "ansible"]
	for pkg in $packags; do
		installPackage ${target} ${pkg}
	done

	# if distri is RedHat based ensure mkpasswd is present on system
	if [[ ${targe} == "RedHat" ]]; then
		installPackage "mkpasswd"
	fi

	# fetching bootstrap-playbook
	fetchPlaybook

	#####
	# configure playbook environment
	#
	# ansible tag-groups:
	#   - check_vars
	# 	- sys
	#   - user
	#	- config
	#	- dnf-extra
	# 	- tailscale
	#	- rport
	# 	- cockpit
	#	- ssh
	#	- fusion-inventory
	#	- nsclient
	#	- motd
	#####
	declare ansibleTags
	declare ansibleVars

	ansibleTagsb += "sys,"
	# only on RedHat based systems, without possibility of skipping
	if [[ ${target} == "RedHat" ]]; then
		ansibleTags += "dnf-extra,"
	fi

	# set hostname
	# ansible tag-group: sys
	ansibleVars += "hostname=$(configureHostname) "

	# creating maintaining user for ansible
	# ansible tag-group: sys
	maintainuservar = $(configureMaintainUser)
	ansibleVars += "maintainuser=$(echo ${maintainuservar} | cut -d ' ' -f1) "
	ansibleVars += "maintainuserpw=$(echo ${maintainuservar} | cut -d ' ' -f2) "

	# check if tailscale should be installed
	# ansible tag-group: tailscale
	tailscaleconfig=$(configureTailscale)
	if [[ $(echo ${tailscaleconfig} | cut -d ' ' -f1 == "enabled") ]]; then
		ansibleTags += "tailscale,"
		ansibleVars += ""
	fi


	# execute playbook
	cd /tmp/bootstrap/
	invokePlaybook $ansibleTags $ansibleVars
}


#####
# script entrypoint
#
# we will check if this script is sourced in another script or
# if it a stand alone script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main
fi