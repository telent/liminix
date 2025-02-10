{
  fetchurl,
  writeFennel,
  fennel,
  fennelrepl,
  runCommand,
  lua,
  anoia,
  linotify,
  lualinux,
  stdenv,
}:
let
  name = "watch-ssh-keys";
in
stdenv.mkDerivation {
  inherit name;
  src = ./.;

  buildInputs = [ lua ];
  nativeBuildInputs = [ fennelrepl ];

  buildPhase = ''
    fennelrepl --test ./watch-ssh-keys.fnl
    cp -p ${
      writeFennel name {
        packages = [
          anoia
          lualinux
          linotify
          fennel
        ];
        macros = [
          anoia.dev
        ];
        mainFunction = "run";
      } ./watch-ssh-keys.fnl
    } ${name}
  '';

  installPhase = ''
    install -D ${name} $out/bin/${name}
  '';
}
