TARGETS=go1.10 go1.11 go1.12 go1.13 go1.14

build:
	error=0
	@$(foreach var,$(TARGETS), \
		$(MAKE) -C $(var) $@ || error=1; \
		$(MAKE) -C $(var) -f Makefile.debian7 $@ || error=1; \
		$(MAKE) -C $(var) -f Makefile.debian8 $@ || error=1; \
		$(MAKE) -C $(var) -f Makefile.debian9 $@ || error=1;)
	@make -C fpm $@ || error=1
	exit $(error)

# Requires login at https://docker.elastic.co:7000/.
push:
	error=0
	@$(foreach var,$(TARGETS), \
		$(MAKE) -C $(var) $@ || error=1; \
		$(MAKE) -C $(var) -f Makefile.debian7 $@ || error=1; \
		$(MAKE) -C $(var) -f Makefile.debian8 $@ || error=1; \
		$(MAKE) -C $(var) -f Makefile.debian9 $@ || error=1;)
	@make -C fpm $@ || error=1
	exit $(error)

.PHONY: build push
