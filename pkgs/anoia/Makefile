servicedir:=$(shell mktemp -d)

default: fs.lua init.lua nl.lua svc.lua net/constants.lua

CHECK=fs.fnl init.fnl  svc.fnl

check:
	ln -s . anoia
	fennel ./run-tests.fnl $(CHECK)
	fennel test.fnl
	fennel test-svc.fnl $(servicedir)
	test -f $(servicedir)/fish
	test "`cat $(servicedir)/fish`" = "food"
	test -d $(servicedir)/nested/path
	test "`cat $(servicedir)/nested/path/name`" = "value"
	test "`cat $(servicedir)/nested/path/complex/attribute`" = "val"
	test "`cat $(servicedir)/nested/path/complex/other`" = "42"


net/constants.lua: net/constants.c
	$(CC) -imacros sys/socket.h -imacros linux/netlink.h -E -P - < net/constants.c  | sed 's/ *$$//g' | cat -s > net/constants.lua


%.lua: %.fnl
	fennel --compile $< > $@
