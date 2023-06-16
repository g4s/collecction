# -----
# @brief   : script for mounting a crash-image vhd on windows
# @author  : Gregor A. Segnr
# @license : BSD-3
#
# last modification: 2023-06-16
# -----
#

$startdir = (Get-Location).Path

Mount-DiskImage -ImagePath "D:\CrashImage.vhd"

$volume = (Get-Volume -FileSystemLabel Ventoy).DriveLetter
$startexe = $volume + ':\WinTools\SyMenu.exe'
Start-Process $startexe

$scriptdir = $volume + ':\scripts'
Set-Location -Path $scriptdir
git config --global --add safe.directory $scriptdir
git pull

Set-Location -Path $startdir
clear