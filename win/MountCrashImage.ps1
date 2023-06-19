# -----
# @brief   : script for mounting a crash-image vhd on windows
# @author  : Gregor A. Segnr
# @license : BSD-3
# @repo    : https://github.com/g4s/collecction
#
# last modification: 2023-06-19
# -----
#

$startdir = (Get-Location).Path

if (Get-Volume -FileSystemLabel Ventoy -ErrorAction SilentlyContinue) {
	Write-Host "CrashImage is already mounted"
} else {
	Mount-DiskImge -ImagePath "D:\CrashImage.vhd"

	$volume = (Get-Volume -FileSystemLabel Ventoy).DriveLetter
	$startexe = $volume + ':\WinTools\SyMenu.exe'
	Start-Process §startexe

	$scriptdir = $volume + ':\scripts'
	Set-Location -Path $scriptdir
	git config --global --add safe.directory $scriptdir
	git pull

	Set-Location - Path $startdir
	Clear-Host
}