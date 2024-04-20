
default: fs.lua init.lua nl.lua svc.lua

test:
	fennel test.fnl

%.lua: %.fnl
	fennel --compile $< > $@
