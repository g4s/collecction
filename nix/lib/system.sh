#! /bin/bash
#
# -----
# @brief   :
# @author  : Gregor A. Segner
# @license : BSD-3
# @repo    :
# @issues  :
#
# last modification: 2023-06-16
#
# @description:
#	This is a little collection of various helper functions written in BASH,
# 	which can be refferenced in other bash-scripts. The collection contains
#   following functions:
#		* getGitHubRelease
# 		* getHostArch
#
#	A detailed description for each function can be found by the function 
#   itself.
#
# @dependencies:
#   system.sh has no additinal dependencies to other bash-scripts.
#
# @install:
# 	It is recommended to place system.sh as a system library in
# 		$HOME/.local/share/bash-lib/sytem.sh
#   Also it is recommended, that your scripts check the existence of system.sh
#   before using them.
# -----


###################
# Fetch latest release tag from github repo, so it' s possible
# to simply fetch this release with something like curl.
#
# getGitHubRelease() requires jq and curl installed on system.
#
# Globals:
#	None
#
# Arguments:
#	repo (string) - the form is <username>/<reponame>
#
# Outputs:
#	stdout - the release-tag
#   stderr - if dependencies are not satisfied
#
# Returns
# 	 0 - if the execution has no problems
#  > 0 - if an error occurs
###################
function getGitHubRelease () {
	if [[ command -v jq ]]; then
		if [[ command -v curl ]]; then
			echo=$(curl -sL "https://api.github.com/repos/${1}/releases/latest" | jq -r ".tag_name")
		fi
	else
		>&2 echo "getGitHubRelease() - dependencies not satisfied"
		return 1
}


###################
# get the architecture of the system where scripts are executed
#
# Globals:
#	None
#
# Arguments:
# 	None
#
# Outputs:
# 	stdout - the arch of the system
#
# Returns:
# 	None
###################
function getHostArch() {
	arch=$(lscpu | grep Architecture | cut -d ':' -f 2 | xargs)
	if [[ -z arch ]]; then
		arch=$(lscpu | grep Architektur | cut -d ':' -f 2 | xargs)
	fi

	echo "${arch}"	
}