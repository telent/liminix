DOCS=\
	admin \
	configuration \
	development \
	index \
	installation \
	intro \
	modules \
	outputs \
	reference \
	tutorial


hardware.rst: hardware.nix
	@rm -f hardware.rst || true
	@cp $$(nix-build hardware.nix) hardware.rst

%.html : %.adoc
	asciidoctor -a stylesheet=asciidoc.css $<

html: Makefile $(patsubst %,%.html,$(DOCS))

install:
	mkdir -p $(prefix)/doc
	cp -a posts/* news.html index.html liminix.css $(prefix)
	cp $(patsubst %,%.html,$(DOCS)) $(prefix)/doc
