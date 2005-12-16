MOD := dsmod
VERSION := $(shell cat .version)
NAME := telefon-$(VERSION)
ARCHIVE := $(NAME)-$(MOD).tar.bz2

.PHONY: $(ARCHIVE) build clean check

build: $(ARCHIVE)

$(ARCHIVE): check
	rm -rf ./$(NAME)
	mkdir $(NAME)
	tar c --exclude=.svn -C base . | tar x -C $(NAME)
	tar cvjf $@ --format=oldgnu --owner=root --group=root $(NAME) \
	|| (rm $(ARCHIVE) && false)
	rm -rf ./$(NAME)

check:
	find base -name .svn -prune \
	-or -type f -exec busybox ash -n {} \;

clean:
	-rm telefon*.tar.bz2
	-rm -r telefon-[0-9]*
