{
  liminix
, usb-modeswitch
, ppp
, lib
, svc
, uevent-watch
}:
{ apn, username, password, authType }:
let
  inherit (liminix.services) bundle longrun oneshot;
  authTypeNum = if authType == "pap" then "1" else "2";
  chat = lib.escapeShellArgs [
    # Your usb modem thing might present as a tty that you run PPP
    # over, or as a network device ("ndis" or "ncm"). The latter
    # kind is to be preferred, at least in principle, because it's
    # faster.  This initialization sequence works for the Huawei
    # E3372, and took much swearing: the error messages are *awful*
    "" "AT"
    "OK" "ATZ"
    # create PDP context
    "OK" "AT+CGDCONT=1,\"IP\",\"${apn}\""
    # activate PDP context
    "OK"  "AT+CGACT=1,1"
    # setup username and password per requirements of sim provider.
    # (caret is special to chat, so needs escaping in AT commands)
    "OK"  "AT\\^AUTHDATA=1,${authTypeNum},\"\",\"${password}\",\"${username}\""
    # start the thing (I am choosing to read this as "NDIS DialUP")
    "OK" "AT\\^NDISDUP=1,1"
    "OK"
  ];
  modeswitch = oneshot {
    name = "modem-modeswitch";
    up = ''
      ${usb-modeswitch}/bin/usb_modeswitch -v 12d1 -p 14fe --huawei-new-mode
    '';
  };
  atz = oneshot {
    name = "modem-atz";
    dependencies = [ modeswitch ];
    up = ''
      ls -l /dev/modem
      ${ppp}/bin/chat -s -v ${chat}  0<>/dev/modem 1>&0
    '';
    down = "${ppp}/bin/chat -v '' ATZ OK  0<>/dev/modem 1>&0";
  };
  setup = bundle {
    name = "modemm-mm-mm-mm";
    contents = [
      (longrun {
        name = "watch-for-usb-modeswitch";
        isTrigger = true;
        buildInputs = [ modeswitch ];
        run = "${uevent-watch}/bin/uevent-watch -s ${modeswitch.name} devtype=usb_device product=12d1/14fe/102";
      })
      (longrun {
        name = "watch-for-modem";
        isTrigger = true;
        buildInputs = [ atz ];
        run = "${uevent-watch}/bin/uevent-watch -n /dev/modem -s ${atz.name} subsystem=tty attrs.idVendor=12d1 attrs.idProduct=1506";
      })
    ];
  };
in svc.network.link.build {
  ifname = "wwan0";
  dependencies = [ setup ];
}
