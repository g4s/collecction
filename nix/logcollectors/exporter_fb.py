#! /usr/bin/env python3

import configparser
import deepdiff
import os
import requests
import time

from datetime import date
from fritzconnection.lib.fritzstatus import FritzStatus

def main():
    today = date.todate.strftime('%d.%m.%y')

    conf = configparser.ConfigParser()

    # load configuration from env, if exporter is invoced by systemd
    if os.getenv("INVOCATION_ID"):
        conf['fritzbox'] = {}
        conf['fritzbox']['url'] =  os.environ.get('FRITZBOX')
        conf['fritzbox']['user'] = os.environ.get('FB_USER') or ""
        conf['fritzbox']['password'] = os.environ.get('FB_PASS') or ""

        conf['prometheus'] = {}
        conf['prometheus']['uri']  = os.environ.get('PROMETHEUS_URI')
        conf['prometheus']['port'] = os.environ.get('PROMETHEUS_PORT') or "9090"

    def fetchLog(fritzcon):
        pass

    def writePrometheus(config, msgline):
        pass

    fc = FritzStatus(address=conf['fritzbox']['url'], password="")
    logbuffer = ""

    while True:
        localbuffer = fetchLog(fc)
        
        delta = deepdiff.DeepDiff(logbuffer, localbuffer, ignore_string_case=True)

        for line in delta.values_changed.root:
            logbuffer.append(line.new_value)
            writePrometheus(conf['prometheus'], line)

        time.sleep(60)