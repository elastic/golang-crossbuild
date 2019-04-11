GO_VERSIONS=go1.10 go1.11 go1.12
TARGETS=$(GO_VERSIONS) fpm

build:
	@$(foreach var,$(TARGETS), \
		$(MAKE) -C $(var) $@; \
		$(MAKE) -C $(var) -f Makefile.debian7 $@; \
		$(MAKE) -C $(var) -f Makefile.debian8 $@;)

# Requires login at https://docker.elastic.co:7000/.
push:
	@$(foreach var,$(TARGETS), \
		$(MAKE) -C $(var) $@; \
		$(MAKE) -C $(var) -f Makefile.debian7 $@; \
		$(MAKE) -C $(var) -f Makefile.debian8 $@;)

.PHONY: build push
