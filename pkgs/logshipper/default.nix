{
  stdenv,
}:
stdenv.mkDerivation {
  name = "logshipper";
  makeFlags = [ "PREFIX=${placeholder "out"}" ];
  src = ./.;
}
