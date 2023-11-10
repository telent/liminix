{
  # "standard" modules that aren't fundamentally required,
  # but are probably useful in most common workflows and
  # you should have to opt out of instead of into
  imports = [
    ./tftpboot.nix
    ./kexecboot.nix
    ./outputs/flashimage.nix
    ./jffs2.nix
    ./ubifs.nix
  ];
}
