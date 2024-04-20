
default: fs.lua init.lua nl.lua svc.lua

test:
	ln -s . anoia
	fennel test.fnl

%.lua: %.fnl
	fennel --compile $< > $@
