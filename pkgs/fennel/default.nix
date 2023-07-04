{
  stdenv
, lua
, fetchFromSourcehut
}:
let pname =  "fennel";
in stdenv.mkDerivation {
  inherit pname;
  version = "1.3";
  nativeBuildInputs = [ lua ];  # used in build
  buildInputs = [ lua ];        # needed for patchShebangs
  src = fetchFromSourcehut {
    owner = "~technomancy";
    repo = pname;
    rev = "1.3.0";
    hash = "sha256-DXJOdYzfjTncqL7BsDbdvZcauDMkZV2X0U0FfhfwQrw=";
  };
  makeFlags = [ "PREFIX=${placeholder "out"}" ];
}
