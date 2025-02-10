{
  stdenv,
  git,
  python2,
  which,
  fetchgit,
  fetchFromGitHub,
  coccinelle,
}:
let
  donorTree = fetchFromGitHub {
    owner = "torvalds";
    repo = "linux";
    rev = "e2c1a934fd8e4288e7a32f4088ceaccf469eb74c"; # 5.15.94
    hash = "sha256-Jg3EgL86CseuzYMAlUG3CDWPCo8glMSIZs10l7EuhWI=";
  };
  backports = stdenv.mkDerivation {
    name = "linux-backports";
    version = "dfe0f60ca8a";
    nativeBuildInputs = [ python2 ];

    src = fetchgit {
      url = "https://git.kernel.org/pub/scm/linux/kernel/git/backports/backports.git";
      name = "backports";
      rev = "dfe0f60ca8a1065e63b4db703b3bd2708ee23a0e";
      hash = "sha256-V+unO0rCom+TZS7WuaXFrb3C1EBImmflCPuOoP+LvBY=";
    };
    buildPhase = ''
      patchShebangs .
    '';
    installPhase = ''
      mkdir -p $out
      cp -a . $out
      rm $out/patches/0073-netdevice-mtu-range.cocci
      # fq.patch is obsoleted by kernel commit 48a54f6bc45 and no longer
      # applies
      # rm $out/patches/0091-fq-no-siphash_key_t/fq.patch
      # don't know why this doesn't apply but it's only important for
      # compiling against linux < 4.1
      # rm $out/patches/0058-ptp_getsettime64/ptp_getsettime64.cocci
    '';
    patches = [
      # (fetchpatch {
      #   url = "https://github.com/telent/nixwrt/blob/28ff2559e811c740b0a2922f52291b335804857b/nixwrt/kernel/gentree-writable-outputs.patch";
      #   hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
      # })#
      ./gentree-writable-outputs.patch
      #      ./update-usb-sg-backport-patch.patch
      #      ./backport_kfree_sensitive.patch
    ];
  };
in
stdenv.mkDerivation rec {
  inherit donorTree;
  KERNEL_VERSION = builtins.substring 0 11 donorTree.rev;
  BACKPORTS_VERSION = backports.version;
  name = "backported-kernel-${KERNEL_VERSION}-${BACKPORTS_VERSION}";

  # gentree uses "which" at runtime to test for the presence of git,
  # and I don't have the patience to patch it out. There is no other
  # reason we need either of them as build inputs.
  depsBuildBuild = [ coccinelle ];
  nativeBuildInputs = [
    which
    git
    python2
  ];

  phases = [
    "backportFromFuture"
    "installPhase"
  ];

  backportFromFuture = ''
    echo $KERNEL_VERSION $BACKPORTS_VERSION
    WORK=`pwd`/build
    mkdir -p $WORK
    cat ${backports}/copy-list > copy-list
    echo 'include/linux/key.h' >> copy-list
    python  ${backports}/gentree.py --verbose --clean  --copy-list copy-list ${donorTree} $WORK
  '';
  installPhase = ''
    cp -a ./build/ $out
  '';
}
