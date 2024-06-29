{ writeFennel
, stdenv
}:
name : packages : source :
writeFennel name { inherit packages; } source
