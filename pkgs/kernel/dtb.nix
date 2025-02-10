{
  stdenv,
  dtc,
  lib,
  runCommand,
  writeText,
}:
{
  dts,
  includes,
  commandLine,
}:
let
  cppDtSearchFlags = builtins.concatStringsSep " " (map (f: "-I${f}") includes);
  dtcSearchFlags = builtins.concatStringsSep " " (map (f: "-i${f}") includes);
  cmdline = lib.concatStringsSep " " commandLine;
  chosen = writeText "chosen.dtsi" "/{ chosen { bootargs = ${builtins.toJSON cmdline}; }; };";
  combined = writeText "combined-dts-fragments" (
    lib.concatStrings (builtins.map (f: "#include \"${f}\"\n") (dts ++ [ chosen ]))
  );
in
stdenv.mkDerivation {
  name = "dtb";
  phases = [ "buildPhase" ];
  nativeBuildInputs = [ dtc ];
  buildPhase = ''
    ${stdenv.cc.targetPrefix}cpp -nostdinc -x assembler-with-cpp ${cppDtSearchFlags} -undef -D__DTS__  -o dtb.tmp ${combined}
    dtc ${dtcSearchFlags} -I dts  -O dtb -o $out dtb.tmp
    # dtc -I dtb  -O dts  $out
    test -e $out
  '';
}
