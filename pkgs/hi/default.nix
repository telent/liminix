# A "hello world" program that's smaller than the GNU
# one. Used for testing the toolchain/linker behaviour.
{
  runCommandCC,
}:
let
  code = ''
    #include <stdio.h>
    int main()
    {
      printf("hello world\n");
      return 0;
    }
  '';
in
runCommandCC "hello"
  {
    name = "hi";
    inherit code;
    executable = true;
    # hardeningDisable = ["all"];
    passAsFile = [ "code" ];
    preferLocalBuild = true;
    allowSubstitutes = false;
  }
  ''
    n=$out/bin/$name
    mkdir -p "$(dirname "$n")"
    mv "$codePath" code.c
    $CC -x c code.c -o "$n"
  ''
