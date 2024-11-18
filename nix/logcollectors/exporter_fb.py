#! /usr/bin/env python3

import configparser
import os
import requests
import time

from dateitime import date
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
        conf['prometheus']['port'] = os.environ.get('PROMETHEUS_PORT') or "8080"

    def fetchLog(fritzcon):
        pass

    def writePrometheus(config, msgline):
        pass

    fc = FritzStastus(address="", password="")
    logbuffer = ""

    while True:
        localbuffer = fetchLog(fc)

        for line in logbuffer:
            for tmpline in localbuffer:
                if (tmpline not in line):
                    writePrometheus(conf['prometheus'], tmpline)
        time.sleep(60)