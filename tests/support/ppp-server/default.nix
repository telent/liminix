{
  stdenv
, python3
, qemu
, fetchzip
, writeShellApplication
}:
let
  chr-image = fetchzip {
    url = "https://download.mikrotik.com/routeros/7.7/chr-7.7.img.zip";
    hash = "sha256-utBQMUgNvl/UTG+GjnQShlGgVtHmRKtnhSTWW/JyeiY=";
    curlOpts = "-L";
  };
  ros-exec-script = stdenv.mkDerivation {
    name = "ros-exec-script";
    src = ./.;
    buildInputs = [python3];
    buildPhase = ":";
    installPhase = ''
      mkdir -p $out/bin
      cp ros-exec-script.py $out/bin/ros-exec-script
      chmod +x $out/bin/ros-exec-script
    '';
  };
  routeros = writeShellApplication {
    name = "routeros";
    runtimeInputs = [ qemu ros-exec-script ];
    text = ''
    RUNTIME_DIRECTORY=$1
    test -d "$RUNTIME_DIRECTORY" || exit 1
    ${qemu}/bin/qemu-system-x86_64 \
      -M q35  \
      -m 1024 \
      -accel kvm \
      -display none \
      -daemonize \
      -pidfile "$RUNTIME_DIRECTORY/pid" \
      -serial "unix:$RUNTIME_DIRECTORY/console,server,nowait"\
      -monitor "unix:$RUNTIME_DIRECTORY/monitor,server,nowait" \
      -snapshot -drive file=${chr-image}/chr-7.7.img,format=raw,if=virtio \
      -chardev "socket,path=$RUNTIME_DIRECTORY/qmp,server=on,wait=off,id=qga0" \
      -device virtio-serial \
      -device virtserialport,chardev=qga0,name=org.qemu.guest_agent.0 \
      -netdev socket,id=access,mcast=230.0.0.1:1234,localaddr=127.0.0.1 \
      -device virtio-net-pci,disable-legacy=on,disable-modern=off,netdev=access,mac=ba:ad:1d:ea:11:02 \
      -netdev socket,id=world,mcast=230.0.0.1:1236,localaddr=127.0.0.1 \
      -device virtio-net-pci,disable-legacy=on,disable-modern=off,netdev=world,mac=ba:ad:1d:ea:11:01
    ros-exec-script "$RUNTIME_DIRECTORY/qmp" ${./routeros.config}
    '';
  };
in {
  inherit routeros ros-exec-script;
}
