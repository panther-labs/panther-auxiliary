#!/usr/bin/env python3

import argparse
import json
import fileinput
import ipaddress
import logging
from os import path

from datetime import datetime, timedelta
from greynoise import GreyNoise

FILENAME = "greynoise_noise_lut.jsonl"
API_KEY = 'REPLACE ME'


def run(args):
    logging.basicConfig( level=args.loglevel.upper() )
    session = GreyNoise(api_key=API_KEY, integration_name="panther-lut-puller")
    if path.isfile(FILENAME):
        logging.info('file exists')
        update(session)
    else:
        logging.info('file does not exist')
        bootstrap(session)

def update(session):
    update_query = 'last_seen:1d'
    new_data = fetch_results(session, update_query)
    
    # We'll consider anything not seen in 7 days stale
    stale_time = datetime.now() - timedelta(days=7)

    # Copy over all the old data that does not exist in the new data and is not stale
    for line in fileinput.input(files=FILENAME, inplace=True, backup='.bak'):
        old_indicator = json.loads(line)

        # Skip entries that are stale
        last_seen = datetime.strptime(old_indicator['last_seen'], '%Y-%m-%d')
        if last_seen < stale_time:
            continue

        # Write indicators that exist in the old set but not the new
        if old_indicator.get('ip') not in new_data:
            print(line, end='')
            continue

    # Now append all the new data
    with open(FILENAME, "a") as lut:
        for indicator in new_data.values():
            # Skip Bogon and RFC1918 IP addresses
            if not ipaddress.ip_address(indicator['ip']).is_global:
                continue
            lut.write(json.dumps(indicator) + "\n")
    

# When this runs without an existing file, grab the last 90 days of indicators
def bootstrap(session):
    bootstrap_query = 'last_seen:7d'

    page = 1
    logging.info('Fetching page 1')
    response = session.query(bootstrap_query)
    scroll = response['scroll']
    with open(FILENAME, "w") as lut:
        for indicator in response["data"]:
            # Skip Bogon and RFC1918 IP addresses
            if not ipaddress.ip_address(indicator['ip']).is_global:
                continue
            lut.write(json.dumps(indicator) + "\n")

    while scroll:
        page += 1
        logging.info(f'Fetching page {page}')
        response = session.query(bootstrap_query, scroll=scroll)
        with open(FILENAME, "a") as lut:
            for indicator in response["data"]:
                # Skip Bogon and RFC1918 IP addresses
                if not ipaddress.ip_address(indicator['ip']).is_global:
                    continue
                lut.write(json.dumps(indicator) + "\n")
        scroll = (response['scroll'] if 'scroll' in response else False)


def fetch_results(session, query):
    page = 1
    ip_keyed_data = {}
    logging.info('Fetching page 1')

    response = session.query(query)
    scroll = response['scroll']
    for indicator in response["data"]:
        ip_keyed_data[indicator.get('ip', 'no_ip')] = indicator

    while scroll:
        page += 1
        logging.info(f'Fetching page {page}')
        response = session.query(query, scroll=scroll)
        for indicator in response["data"]:
            ip_keyed_data[indicator.get('ip', 'no_ip')] = indicator
        scroll = (response['scroll'] if 'scroll' in response else False)

    return ip_keyed_data
    

def setup():
    parser = argparse.ArgumentParser()
    parser.add_argument( '-log', '--loglevel', default='warning',
        choices=logging._nameToLevel.keys(),
        help='Provide logging level. Example --loglevel debug, default=warning' )
    args = parser.parse_args()
    return args


if __name__ == "__main__":
    args = setup()
    run(args)
