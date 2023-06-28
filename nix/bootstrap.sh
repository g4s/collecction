#! /usr/bin/env bash
# shellcheck disable=
#
# -----
# @brief     : script for initiating bootstrapping on linux hosts
# @author    : Gregor A. Segner
# @license   : BSD-3
#
# @plattform : *nix
# @repo      : https://github.com/g4s/collecction
# @issues    : https://github.com/g4s/collecction/issues
#
# version    : development
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
playbook = "https://bit.ly/xxxxx"

checkCommand () {
	return command -v $1
}

checkDistri () {
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


updateSystem () {
	echo "updateing system to latest version..."
	case $1 for in
		Redhat)
			dnf update -y
			;;
	esac
}


installPackage () {
	echo "installing " + $2

	case $1 in
		Redhat)
			dnf install -y $2
			;;
	esac
}


fetchPlaybook () {
	echo "fetching ansible playbook and store under /tmp/bootstrap/"
	mkdir -P /tmp/bootstrap
	curl -s -L ${playbook} -o /tmp/bootstrap/bootstrap.yml
}


invokePlaybook () {
	cd /tmp/bootstrap
	ansible-playbook --connction=local \
		--inventory localhost 127.0.0.1 \
		bootstrap.yml \
		--tags="${1}" \
		--extra-vars="${2}"
}


configureHostname () {
	hostname=
	while [[ $hostname = "" ]]; do
		read -p "please enter the FQDN of the host: " hostname
	done

	echo ${hostname}
}


configureMaintainUser () {
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

		if [[ ${password1} -eq ${password} ]]; then
			rtpassword=$(echo ${password1} | sha512sum)
		fi
	done

	echo ${username} + " " + ${rtpassword}
}

## mainfunction
main () {
	target = $(checkDistri)

	updateSystem ${target}

	# activating EPEL on RedHat based distris
	if [[ $target == 'RedHat' ]]; then
		echo "enable EPEL and update package cache"
		dnf config-manager --set-enabled crb
		dnf install -y epel-release
		dnf makecache

	# installing ansible and dependencies
	packages = ["python3-pip", "ansible"]
	for pkg in$packags; do
		installPackage ${target} ${pkg}
	done

	# if distri is RedHat based ensure mkpasswd is present on system
	if [[ ${targe} == "RedHat" ]]; then
		installPackage "mkpasswd"
    fi

	# fetching bootstrap-playbook
	$(fetchPlaybook)

	#####
	# configure playbook environment
	#####
	declare ansibleTags
	declare ansibleVars

	ansibleTagsb += "sys,"
	# only on RedHat based systems, without possibility of skipping
	if [[ ${target} == "RedHat" ]]; then
		ansibleTags += "dnf-extra,"
	fi

	# set hostname
	ansibleVars += "hostname=$(configureHostname) "

	# creating maintaining user for ansible
	maintainuservar = $(configureMaintainUser)
	ansibleVars += "maintainuser=$(echo ${maintainuservar} | cut -d ' ' -f1) "
	ansibleVars += "maintainuserpw=$(echo ${maintainuservar} | cut -d ' ' -f2) "

	# check if tailscale should be installed
	tailscaleconfig=$(configureTailscale)
	if [[ $(echo ${tailscaleconfig} | cut -d ' ' -f1 == "enabled") ]]; then
		ansibleTags += "tailscale,"
		ansibleVars += ""
	fi


	# execute playbook
	cd /tmp/bootstrap/
	$(invokePlaybook $ansibleTags $ansibleVars)
}


#####
# script entrypoint
$(main)