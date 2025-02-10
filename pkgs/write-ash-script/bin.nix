{
  writeScriptBin,
  lib,
}:
name:
{
  runtimeInputs ? [ ],
}:
text:
writeScriptBin name ''
  #!/bin/sh
  set -o errexit
  set -o nounset
  set -o pipefail

  export PATH="${lib.makeBinPath runtimeInputs}:$PATH"
  ${text}
''
