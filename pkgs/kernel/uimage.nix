{
  lzma,
  stdenv,
  ubootTools,
  dtc,
  lib,
}:
let
  objcopy = "${stdenv.cc.bintools.targetPrefix}objcopy";
  arch = stdenv.hostPlatform.linuxArch;
  stripAndZip = ''
    ${objcopy} -O binary -R .reginfo -R .notes -R .note -R .comment -R .mdebug -R .note.gnu.build-id -S vmlinux.elf vmlinux.bin
    rm -f vmlinux.bin.lzma ; lzma -k -z  vmlinux.bin
  '';
in
{
  kernel,
  commandLine,
  commandLineDtbNode ? "bootargs",
  entryPoint,
  extraName ? "", # e.g. socFamily
  loadAddress,
  imageFormat,
  alignment ? null,
  dtb ? null,
}:
stdenv.mkDerivation {
  name = "kernel.image";
  phases = [
    "preparePhase"
    (
      if commandLine != null then
        assert dtb != null;
        "mungeDtbPhase"
      else
        ":"
    )
    (if imageFormat == "fit" then "buildPhaseFIT" else "buildPhaseUImage")
    "installPhase"
  ];
  nativeBuildInputs = [
    lzma
    dtc
    stdenv.cc
    ubootTools
  ];
  preparePhase = ''
    cp ${kernel} vmlinux.elf; chmod +w vmlinux.elf
  '';
  mungeDtbPhase = ''
    dtc -I dtb -O dts -o tmp.dts ${dtb}
    echo '/{ chosen { ${commandLineDtbNode} = ${builtins.toJSON commandLine}; }; };'  >> tmp.dts
    dtc -I dts -O dtb -o tmp.dtb tmp.dts
  '';

  buildPhaseUImage = ''
    test -f tmp.dtb && ${objcopy} --update-section .appended_dtb=tmp.dtb vmlinux.elf || ${objcopy} --add-section .appended_dtb=tmp.dtb vmlinux.elf
    ${stripAndZip}
    mkimage -A ${arch} -O linux -T kernel -C lzma -a 0x${lib.toHexString loadAddress} -e 0x${lib.toHexString entryPoint} -n '${lib.toUpper arch} Liminix Linux ${extraName}' -d vmlinux.bin.lzma kernel.uimage
  '';

  buildPhaseFIT = ''
    ${stripAndZip}
    cat ${./kernel_fdt.its} > mkimage.its
    cat << _VARS  >> mkimage.its
    / {
        images {
            kernel {
                data = /incbin/("./vmlinux.bin.lzma");
                load = <0x${lib.toHexString loadAddress}>;
                entry = <0x${lib.toHexString entryPoint}>;
                arch = "${arch}";
                compression = "lzma";
            };
            fdt-1 {
                data = /incbin/("./tmp.dtb");
                arch = "${arch}";
            };
        };
    };
    _VARS
    mkimage -f mkimage.its -E ${
      lib.optionalString (alignment != null) "-B 0x${lib.toHexString alignment}"
    } kernel.uimage
    mkimage -l kernel.uimage
  '';

  installPhase = ''
    cp kernel.uimage $out
  '';
}
