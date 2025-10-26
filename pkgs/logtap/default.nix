{
  stdenv,
  fennelc,
  lualinux,
  lua,
  anoia
}:
stdenv.mkDerivation {
  name = "logtap";
  nativeBuildInputs = [ fennelc ];
  buildInputs = [ lua lualinux anoia ];
  makeFlags = [ "PREFIX=${placeholder "out"}" ];
  src = ./.;
}
