TARGETS=logtap backfill
CFLAGS=-Wall
default: $(TARGETS)

backfill: backfill.fnl
	fennelc $<

install: $(TARGETS)
	install -Dt $(PREFIX)/bin/ $(TARGETS)
