import argparse

from fritzconnection import FritzConnection

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog = 'reboot-fritzbox.py',
        description = 'short helper for rebooting a Fritz!Box from remote.'
        )
        
    parser.add_argument('-a', '--address', required=True)
    parser.add_argument('-u', '--user', default=None)
    parser.add_argument('-p', '--password', required=True)
    
    args = parser.parse_args()
    
    fc = FritzConnection(
        address = args['address'],
        user = args['user'],
        password = args['password']
        )
        
    wanstate = fc.call_action('WANIPConnection', 'GetStatusInfo', arguments='NewConnectionStatus')
    
    if wanstate != 'connected':
        fc.reboot() 