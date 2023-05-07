killpid(){
  if test -e $1 && test -d /proc/`cat $1` ; then
    pid=$(cat $1)
    kill $pid
  fi
}

cleanup(){
  killpid $serverstatedir/pid
  test -n "$MPLCONFIGDIR" && test -d "$MPLCONFIGDIR" && rm -rf "$MPLCONFIGDIR"
  killpid foo.pid
  killpid ./vm/pid
}
trap cleanup EXIT

fatal(){
  err=$?
  echo "FAIL: command $(eval echo $BASH_COMMAND) exited with code $err"
  exit $err
}
trap fatal ERR
