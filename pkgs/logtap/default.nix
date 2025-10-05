{
  stdenv,
}:
stdenv.mkDerivation {
  name = "logtap";
  makeFlags = [ "PREFIX=${placeholder "out"}" ];
  src = ./.;
}
