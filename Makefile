TARGETS=go1.10 go1.11 go1.12 go1.13 go1.14 go1.15
ARM_TARGETS=go1.15

build: status=".status.build"
build:
	@echo '0' > ${status}
	@$(foreach var,$(TARGETS), \
		$(MAKE) -C $(var) $@; || echo '1' > ${status}; \
		$(MAKE) -C $(var) -f Makefile.debian7 $@; || echo '1' > ${status}; \
		$(MAKE) -C $(var) -f Makefile.debian8 $@; || echo '1' > ${status}; \
		$(MAKE) -C $(var) -f Makefile.debian9 $@; || echo '1' > ${status}; \
		$(MAKE) -C $(var) -f Makefile.debian10 $@; || echo '1' > ${status};)
	@make -C fpm $@ || echo '1' > ${status}
	exit $$(cat ${status})

build-arm: status=".status.build.arm"
build-arm:
	@echo '0' > ${status}
	@$(foreach var,$(ARM_TARGETS), \
		$(MAKE) -C $(var) $@; || echo '1' > ${status}; \
		$(MAKE) -C $(var) -f Makefile.debian7 $@; || echo '1' > ${status}; \
		$(MAKE) -C $(var) -f Makefile.debian8 $@; || echo '1' > ${status}; \
		$(MAKE) -C $(var) -f Makefile.debian9 $@; || echo '1' > ${status}; \
		$(MAKE) -C $(var) -f Makefile.debian10 $@; || echo '1' > ${status};)
	@make -C fpm $@ || echo '1' > ${status}
	exit $$(cat ${status})

# Requires login at https://docker.elastic.co:7000/.
push: status=".status.push"
push:
	@echo '0' > ${status}
	@$(foreach var,$(TARGETS), \
		$(MAKE) -C $(var) $@ || echo '1' > ${status}; \
		$(MAKE) -C $(var) -f Makefile.debian7 $@ || echo '1' > ${status}; \
		$(MAKE) -C $(var) -f Makefile.debian8 $@ || echo '1' > ${status}; \
		$(MAKE) -C $(var) -f Makefile.debian9 $@ || echo '1' > ${status}; \
		$(MAKE) -C $(var) -f Makefile.debian10 $@ || echo '1' > ${status};)
	@make -C fpm $@ || echo '1' > ${status}
	exit $$(cat ${status})

.PHONY: build push
