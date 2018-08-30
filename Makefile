build:
	@make -C go1.10 $@
	@make -C go1.10 -f Makefile.debian7 $@
	@make -C go1.11 $@
	@make -C go1.11 -f Makefile.debian7 $@
	@make -C fpm $@

# Requires login at https://docker.elastic.co:7000/.
push:
	@make -C go1.10 $@
	@make -C go1.10 -f Makefile.debian7 $@
	@make -C go1.11 $@
	@make -C go1.11 -f Makefile.debian7 $@
	@make -C fpm $@

.PHONY: build push
