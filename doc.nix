{ stdenv,
  lib,
  liminix,
  gnumake,
  fennel,
  pandoc,
  luaPackages,
  asciidoctor,
  borderVmConf
}:
let
  json =
    (import liminix {
      inherit borderVmConf;
      device = import (liminix + "/devices/qemu");
      liminix-config =
        { ... }:
        {
          imports = [ ./modules/all-modules.nix ];
        };
    }).outputs.optionsJson;
in
stdenv.mkDerivation {
  name = "liminix-doc";
  nativeBuildInputs = [
    gnumake
    fennel
    pandoc
    asciidoctor
    luaPackages.lyaml
  ];

  src = lib.sources.sourceFilesBySuffices
    (lib.cleanSource ./. ) [
      ".adoc"
      ".nix" ".rst" "Makefile" ".svg"
      ".fnl" ".py" ".css" ".html"
      ".md" ".html.in"
    ];

  buildPhase = ''
    cat ${json} | fennel --correlate doc/parse-options.fnl > doc/modules-generated.inc.rst
    cat ${json} | fennel --correlate doc/parse-options-outputs.fnl     > doc/outputs-generated.inc.rst
    cp ${(import ./doc/hardware.nix)} doc/hardware.rst
    make -C doc html
  '';
  installPhase = ''
    mkdir -p $out/nix-support $out/share/
    cd doc
    make install prefix=$out/share
    ln -s ${json} $out/options.json
    echo "file source-dist \"$out/share/doc/liminix\"" \
        > $out/nix-support/hydra-build-products
  '';
}
