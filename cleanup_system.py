#! /usr/bin/env python3
#
# cross-paltform script for cleaning up machines.
#
# on POSIX-machines this script will:
#  - remove old packages
#  - cleanup package cache
#  - on systemd-hosts: remove journals older then 7 days
#  - remove all files inside /tmp/

import argparse
import os
import platform
import shutil
import subprocess
import sys

from pathlib import Path

def writeOutput(str, silent):
    """
        A simple wrapper around print(), which can be used for silence outputs
    """
    if not silent:
        print(str)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument
    parser.add_argument(
        "--trmm", 
        help="running in tactical rmm compability mode",
        action="store_true"
        )
    parser.add_argument(
        "--silence",
        help="silencing output",
        default=False,
        action="store_true"
    )
    args = parser.parse_args()

    if args.trmm:
        writeOutput("running script in TRMM copatibility mode", args.silence)

    match platform.system():
        case 'Windows':
            writeOutput("cleanup script is running on MS Windows", args.silence)

            # @ToDo:
            #   - remove old eventLogs
            #   - remove old restore points
            #   - cleanup %TMPDIR%
            #   - remove dump files (memmory & mini dump)
            #   - remove old updates
            #   - remove unused chocolatey artefacts
            #   - cleanup winget installations

        case "Linux":
            writeOutput("cleanup will be running on Linux", args.silence)

            if os.getuid != 0:
                writeOutput("script is not invoced with sufficient rights - terminate", args.silence)
                sys.exit()

            # check if script is invoced by sytemd on Linux systems
            if os.getenv("INVOCATION_ID"):
                writeOutput("cleanup process is invocated by systemd", args.silence)

            # chreating snapshot if timeshift is presend on system
            if shutil.which("timeshift"):
                writeOutput("found timeshift installed on system: creating snapshot", args.silence)
                subprocess.run(["timeshift", "--create", "--tags 0", "--scripted"])

            # checking for distribution specific things
            distri = platform.freedesktop_os_release()
            match distri["ID"].lower():

                # manage deb based distributions
                case "debian" | "ubuntu":
                    writeOutput("detected apt based system - initiate system cleaning", args.silence)
                    subprocess.run(["apt", "clean"])
                    subprocess.run(["apt", "autoremove", "--purge"])
                    for deb in Path("/var/cache/apt/archives/").glob("*.deb"):
                        os.remove(deb)

                # manage rpm based distributions
                case "fedora":
                    writeOutput("detected rpm based system - initiate system cleaning", args.silence)
                    subprocess.run(["dnf", "autoremove"])
                    subprocess.run(["dnf", "system-upgrade", "clean"])
                    subprocess.run(["dnf", "clean", "packages"])

                # manage all other Linux distributions
                case other:
                        writeOutput("could not identify linux distribution", args.silence)

            #####
            ## proceed with not package manager specific tasks
            #####

            # removing unused oci container
            if shutil.which("podman"):
                writeOutput("found podman on system - will remove old and unsused images", args.silence)
                subprocess.run("podman", "system", "prune -a -f")

            # minimize jouarnd logs
            if shutil.which("journalctl"):
                writeOutput("removing journald entries older then 7 days", args.silence)
                subprocess.run("journalctl", "--vacuum-time=7d")

            # cleaning /tmp
            writeOutput("removing files from /tmp", args.silence)
            for f in Path("/tmp/").glob("*"):
                os.remove(f)

        case "Darwin":
            pass
        case other:
            pass

    writeOutput("all cleanup tasks are executed", args.silence)


if __name__ == "__main__":
    main