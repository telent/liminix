# forge packets for testing liminix and send them via the qemu udp
# multicast socket interface

MCAST_GRP = '230.0.0.1'
MCAST_PORT = 1235
MULTICAST_TTL = 2

TIMEOUT = 10                    # seconds

from warnings import filterwarnings
filterwarnings("ignore")

import random
import binascii
import socket
import time
import json

from builtins import bytes, bytearray

from scapy.all import Ether, IP, UDP, BOOTP, DHCP, sendp, send, raw

class JSONEncoderWithBytes(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, (bytes, bytearray)):
            return obj.decode('utf-8')
        return json.JSONEncoder.default(self, obj)


def dhcp_option(pkt, label):
    if pkt.haslayer(DHCP):
        for i in pkt[DHCP].options:
            l, v = i
            if l == label:
                return v
    return None

def is_dhcp_offer(pkt):
    val = dhcp_option(pkt, 'message-type')
    return (val == 2)



def mac_to_bytes(mac_addr: str) -> bytes:
    """ Converts a MAC address string to bytes.
    """
    return int(mac_addr.replace(":", ""), 16).to_bytes(6, "big")


client_mac = "01:02:03:04:05:06"
discover = (
    Ether(dst="ff:ff:ff:ff:ff:ff") /
    IP(src="0.0.0.0", dst="255.255.255.255") /
    UDP(sport=68, dport=67) /
    BOOTP(
        chaddr=mac_to_bytes(client_mac),
        xid=random.randint(1, 2**32-1),
    ) /
    DHCP(options=[("message-type", "discover"), "end"])
)
payload = raw(discover)

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
sock.settimeout(TIMEOUT)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
sock.setsockopt(socket.IPPROTO_IP, socket.IP_MULTICAST_TTL, MULTICAST_TTL)

sock.bind((MCAST_GRP, MCAST_PORT))
sock.setsockopt(socket.SOL_IP, socket.IP_MULTICAST_IF, socket.inet_aton('127.0.0.1'))
sock.setsockopt(socket.SOL_IP, socket.IP_ADD_MEMBERSHIP,
                socket.inet_aton(MCAST_GRP) + socket.inet_aton('127.0.0.1'))

endtime = time.time() + TIMEOUT
sock.sendto(payload, (MCAST_GRP, MCAST_PORT))

while time.time() < endtime:
  try:
    data, addr = sock.recvfrom(1024)
  except socket.error as e:
    print('recv exception: ', e)
  else:
    reply = Ether(data)
    if is_dhcp_offer(reply):
        opts = dict([o for o in reply[DHCP].options if type(o) is tuple])
        print(json.dumps(opts, cls=JSONEncoderWithBytes))
        exit(0)
exit(1)
