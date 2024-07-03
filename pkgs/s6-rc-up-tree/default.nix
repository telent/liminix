{
  lualinux,
  writeFennel,
  anoia,
  fennel,
  stdenv,
  fennelrepl,
}:
stdenv.mkDerivation {
  name = "s6-rc-up-tree";
  src = ./.;
  nativeBuildInputs = [ fennelrepl ];
  # propagatedBuildInputs = [ s6-rc-up-tree ];
  installPhase = ''
    mkdir -p $out/bin
    cp -p ${writeFennel "s6-rc-up-tree" {
      packages = [fennel
                  # anoia nellie
                  lualinux ] ;
      mainFunction = "run";
    } ./s6-rc-up-tree.fnl } $out/bin/s6-rc-up-tree
  '';
  postBuild = ''
    export PATH=./scripts:$PATH
    patchShebangs ./scripts
    export TEST_LOG=./log
    fail(){ cat $TEST_LOG | od -c; exit 1; }
    expect(){
      test "$(echo $(cat $TEST_LOG))" = "$@" || fail;
    }
    # given a service with no rdepends, starts only that service
    fennelrepl ./test.fnl ${./test-services} turmeric
    expect "turmeric"

    # given a controlled service with no rdepends, starts only that service
    fennelrepl ./test.fnl ${./test-services} wombat
    expect "wombat"

    # uncontrolled rdepends start
    fennelrepl ./test.fnl ${./test-services} thyme
    expect "thyme rosemary"

    # stopped controlled rdepends don't start
    fennelrepl ./test.fnl ${./test-services} enables-wan
    expect "enables-wan" # not wattle, even though it depends

    # started controlled rdepends are running, so starting them is harmless

    # descendants which depend on a _different_ controlled service, which is down, don't start

    # descendants which depend on a _different_ controlled service, which is up, do start

  '';
}
