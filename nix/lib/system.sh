#! /bin/bash


## IN: username/repo
function getGitHubRelease () {
	echo=$(curl -sL "https://api.github.com/repos/${1}/releases/latest" | jq -r ".tag_name")
}


function getHostArch() {
	arch=$(lscpu | grep Architecture | cut -d ':' -f 2 | xargs)
	if [[ -z arch ]]; then
		arch=$(lscpu | grep Architektur | cut -d ':' -f 2 | xargs)
	fi

	echo "${arch}"	
}