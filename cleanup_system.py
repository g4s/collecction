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
import subprocess

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
        case other:
            writeOutput("cleanup opertions will be run on POSIX system", args.silence)
            if platform.system() != "Darwin":
                distri = platform.freedesktop_os_release()
                match distri["ID"].lower():
                    case "debian":
                        writeOutput("detected apt based system - initiate system cleaning", args.silence)
                        subprocess.run(["apt", "clean"])
                        subprocess.run(["apt", "autoremove", "--purge"])
                        for deb in Path("/var/cache/apt/archives/").glob("*.deb"):
                            os.remove(deb)
                    case other:
                        writeOutput("could not identify linux distribution", args.silence)

                if shutil.which("journalctl"):
                    writeOutput("removing journal entries older then 7 days", args.silence)
                    subprocess.run(["jornalctl", "--vacuum-time=7d"])

            writeOutput("removing files from /tmp", args.silence)
            for f in Path('/tmp/').glob("*"):
                os.remove(f)
    writeOutput("all cleanup tasks are executed", args.silence)


if __name__ == "__main__":
    main