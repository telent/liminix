{
  busybox
, writeScript
, lib
}
: name : { runtimeInputs ? [] } : text : writeScript name ''
#!${busybox}/bin/sh
set -o errexit
set -o nounset
set -o pipefail

export PATH="${lib.makeBinPath ([ busybox ] ++ runtimeInputs)}:$PATH"
${text}
''
