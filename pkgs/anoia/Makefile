
default: fs.lua init.lua nl.lua svc.lua net/constants.lua

test:
	ln -s . anoia
	fennel test.fnl
	fennel test-svc.fnl

net/constants.lua: net/constants.c
	$(CC) -imacros sys/socket.h -imacros linux/netlink.h -E -P - < net/constants.c  | sed 's/ *$$//g' | cat -s > net/constants.lua


%.lua: %.fnl
	fennel --compile $< > $@
