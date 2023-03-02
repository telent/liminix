{
  stdenv
, dtc
, lib
}:
{ dts
, includes
, commandLine
}:let
  cppDtSearchFlags = builtins.concatStringsSep " " (map (f: "-I${f}") includes);
  dtcSearchFlags = builtins.concatStringsSep " " (map (f: "-i${f}") includes);
  cmdline = lib.concatStringsSep " " commandLine;
in stdenv.mkDerivation {
  name = "dtb";
  phases = [ "buildPhase" ];
  nativeBuildInputs = [ dtc ];
  buildPhase = ''
    ${stdenv.cc.targetPrefix}cpp -nostdinc -x assembler-with-cpp ${cppDtSearchFlags} -undef -D__DTS__  -o dtb.tmp ${dts}
    echo '/{ chosen { bootargs = ${builtins.toJSON cmdline}; }; };'  >> dtb.tmp
    dtc ${dtcSearchFlags} -I dts  -O dtb -o $out dtb.tmp
    test -e $out
  '';
}
