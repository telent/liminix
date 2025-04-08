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
	# sections in an appendix need to start at ===
	sed -E -i.bak -e 's/^(=*) /=\1 /g' hardware.adoc

html: Makefile  $(patsubst %,%.adoc,$(DOCS))
	asciidoctor  -D _build -d book index.adoc

install:
	mkdir -p $(prefix)/doc
	cp -a _build/* $(prefix)/doc
