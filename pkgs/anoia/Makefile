
default: fs.lua init.lua nl.lua svc.lua

test:
	ln -s . anoia
	fennel test.fnl
	fennel test-svc.fnl

%.lua: %.fnl
	fennel --compile $< > $@
