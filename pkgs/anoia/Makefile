servicedir:=$(shell mktemp -d)
outputdir:=$(servicedir)/.outputs

default: fs.lua init.lua nl.lua svc.lua process.lua net/constants.lua

CHECK=fs.fnl init.fnl svc.fnl process.fnl

check:
	ln -s . anoia
	fennel ./run-tests.fnl $(CHECK)
	fennel test.fnl
	mkdir -p $(outputdir)
	fennel test-svc.fnl $(servicedir)
	find $(outputdir) -ls
	test -f $(outputdir)/fish
	test "`cat $(outputdir)/fish`" = "food"
	test -d $(outputdir)/nested/path
	test "`cat $(outputdir)/nested/path/name`" = "value"
	test "`cat $(outputdir)/nested/path/complex/attribute`" = "val"
	test "`cat $(outputdir)/nested/path/complex/other`" = "42"


net/constants.lua: net/constants.c
	$(CC) -imacros sys/socket.h -imacros linux/netlink.h -E -P - < net/constants.c  | sed 's/ *$$//g' | cat -s > net/constants.lua


%.lua: %.fnl
	fennel --add-macro-path './assert.fnl'  --compile $< > $@
