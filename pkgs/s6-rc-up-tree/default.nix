{
  writeAshScriptBin
}:
writeAshScriptBin "s6-rc-up-tree" {} (builtins.readFile ./s6-rc-up-tree.sh)
