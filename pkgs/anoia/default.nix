{
  bc, # for tests
  fennel,
  stdenv,
  linotify,
  lua,
  lualinux,
  cpio,
}:
let
  pname = "anoia";
in
stdenv.mkDerivation {
  inherit pname;
  version = "0.1";
  src = ./.;
  nativeBuildInputs = [
    fennel
    cpio
    bc
  ];
  buildInputs = with lua.pkgs; [
    linotify
    lualinux
  ];
  outputs = [
    "out"
    "dev"
  ];

  doCheck = true;

  installPhase = ''
    mkdir -p "$out/share/lua/${lua.luaversion}/${pname}"
    find . -name \*.lua | cpio -p -d "$out/share/lua/${lua.luaversion}/${pname}"

    mkdir -p "$dev/share/lua/${lua.luaversion}/${pname}"
    cp assert.fnl "$dev/share/lua/${lua.luaversion}/${pname}"
  '';
}
