DOCS=\
	admin \
	configuration \
	development \
	index \
	installation \
	intro \
	hardware \
	module-options-generated.inc \
	outputs-generated.inc \
	tutorial

%.adoc: %.rst
	pandoc -f rst -t asciidoc $< | sed -E  -e 's/^(=*) /=\1 /g' > $@

hardware.adoc: hardware.nix

html: Makefile  $(patsubst %,%.adoc,$(DOCS))
	asciidoctor  -D _build -d book index.adoc

install:
	mkdir -p $(prefix)/share/doc/liminix
	cp -a _build/* $(prefix)/share/doc/liminix
