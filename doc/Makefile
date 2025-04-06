DOCS=\
	admin \
	configuration \
	development \
	index \
	installation \
	intro \
	modules \
	outputs \
	hardware \
	tutorial

hardware.adoc: hardware.nix
	pandoc -f rst -t asciidoc -o $@ hardware.rst

html: Makefile  $(patsubst %,%.adoc,$(DOCS))
	asciidoctor  -D _build -d book index.adoc

install:
	mkdir -p $(prefix)/doc
	cp -a _build/* $(prefix)/doc
