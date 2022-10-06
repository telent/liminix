{
  stdenv
, openwrt
, dtc
, kernel
}:
{ dts
}:let
  includes = [
    "${openwrt}/target/linux/ath79/dts"
    "${kernel}/include"
  ];
  cppDtSearchFlags = builtins.concatStringsSep " " (map (f: "-I${f}") includes);
  dtcSearchFlags = builtins.concatStringsSep " " (map (f: "-i${f}") includes);
in stdenv.mkDerivation {
  name = "dtb";
  phases = [ "buildPhase" ];
  nativeBuildInputs = [ dtc ];
  buildPhase = ''
    ${stdenv.cc.targetPrefix}cpp -nostdinc -x assembler-with-cpp ${cppDtSearchFlags} -undef -D__DTS__  -o dtb.tmp ${openwrt}/target/linux/ath79/dts/${dts}
    dtc ${dtcSearchFlags} -I dts  -O dtb -o $out dtb.tmp
    test -e $out
  '';
}
