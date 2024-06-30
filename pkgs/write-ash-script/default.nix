{ writeScript, lib }:
name:
{
  runtimeInputs ? [ ],
}:
text:
writeScript name ''
  #!/bin/sh
  set -o errexit
  set -o nounset
  set -o pipefail

  export PATH="${lib.makeBinPath runtimeInputs}:$PATH"
  ${text}
''
