{
  lzma
, stdenv
, ubootTools
, dtc
, lib
} :
let
  objcopy = "${stdenv.cc.bintools.targetPrefix}objcopy";
in {
  kernel
, commandLine
, entryPoint
, extraName ? ""                # e.g. socFamily
, loadAddress
, dtb ? null
} :
stdenv.mkDerivation {
  name = "kernel.image";
  phases = [
    "preparePhase"
    (if dtb != null then "dtbPhase" else ":")
    "buildPhase"
    "installPhase" ];
  nativeBuildInputs = [
    lzma
    dtc
    stdenv.cc
    ubootTools
  ];
  preparePhase = ''
    cp ${kernel} vmlinux.elf; chmod +w vmlinux.elf
  '';
  dtbPhase = ''
    dtc -I dtb -O dts -o tmp.dts ${dtb}
    echo '/{ chosen { bootargs = ${builtins.toJSON commandLine}; }; };'  >> tmp.dts
    dtc -I dts -O dtb -o tmp.dtb tmp.dts
	  ${objcopy} --update-section .appended_dtb=tmp.dtb vmlinux.elf || ${objcopy} --add-section .appended_dtb=${dtb} vmlinux.elf
  '';

  buildPhase =
    let arch =
          # per output of "mkimage -A list". I *think* these
          # are the same as the kernel arch convention, but
          # maybe that's coincidence
          if stdenv.isMips
          then "mips"
          else if stdenv.isAarch64
          then "arm64"
          else throw "unknown arch";
    in ''
      ${objcopy} -O binary -R .reginfo -R .notes -R .note -R .comment -R .mdebug -R .note.gnu.build-id -S vmlinux.elf vmlinux.bin
      rm -f vmlinux.bin.lzma ; lzma -k -z  vmlinux.bin
      mkimage -A ${arch} -O linux -T kernel -C lzma -a ${loadAddress} -e ${entryPoint} -n '${lib.toUpper arch} Liminix Linux ${extraName}' -d vmlinux.bin.lzma kernel.uimage
    '';
  installPhase = ''
    cp kernel.uimage $out
  '';
}
