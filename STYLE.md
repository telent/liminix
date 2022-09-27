# Some notes on Nix language style

In an attempt to keep this more consistent than NixWRT ended up being,
here is a Nix language style guide for this repo.

* favour `callPackage` over raw `import` for calling derivations
or any function that may generate one - any code that might need
`pkgs` or parts of it.

* prefer `let inherit (quark) up down strange charm` over `with
quark`, in any context where the scope is more than a single
expression or there is more than one reference to `up`, `down` etc.
`with pkgs; [ foo bar baz]` is OK,
`with lib; stdenv.mkDerivation { ... } ` is usually not.

* <liminix> is defined only when running tests, so don't refer to it in
"application" code

* the parameters to a derivation are sorted alphabetically, except for
`lib`, `stdenv` and maybe other non-package "special cases"

* indentation is whatever emacs nix-mode says it is.

  * where a `let` form defines multiple names, put a newline after the
  token `let`, and indent each name two characters

* should it be a package or a module? packages are self-contained -
  they live in /nix/store/eeeeeee-name and don't directly change
  system behaviour by their presence or absense. modules can add to
  /etc or /bin or other global state, create services, all that
  side-effecty stuff.  generally it should be a package unless it
  can't be.
