DESTDIR ?=
PREFIX ?= /usr/local
RUNTIME = $(PREFIX)/share/nvimpager/runtime

nvimpager: nvimpager.in
	sed 's#^RUNTIME=.$$#RUNTIME='"'$(RUNTIME)'"'#' < $< > $@
	chmod +x $@

install: nvimpager
	install -D nvimpager $(DESTDIR)$(PREFIX)/bin
	install -D autoload/pager.vim $(DESTDIR)$(RUNTIME)/autoload