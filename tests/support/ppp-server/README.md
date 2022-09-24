# ppp-server

To test a router, we need an upstream connection. In this directory,
find

* run.sh, a script that will start a RouterOS image in qemu.
  Login when prompted, username is "admin", blank password
* routeros.config, a set of commands you can feed into routeros
  to set up PPPoE

To get the chr-7.5.img image, visit https://mikrotik.com/download and
look in the section titled "Cloud Hosted Router" for "Raw disk image"

You may need to open your firewall a bit to allow multicast packets
so that the upstream and the liminix qemu instances may communicate

config.networking.firewall.extraCommands = ''
ip46tables -A nixos-fw -m pkttype --pkt-type multicast -p udp --dport 1234:1236 -j nixos-fw-accept
'';

## To connect to the routeros serial

The Qemu instance running RouterOS is headless, but it creates
two unix sockets for serial port and monitor.

    socat -,raw,echo=0,icanon=0,isig=0,icrnl=0,escape=0x0f    tests/support/ppp-server/qemu-console

    socat -,raw,echo=0,icanon=0,isig=0,icrnl=0,escape=0x0f    tests/support/ppp-server/qemu-monitor
