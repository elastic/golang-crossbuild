TARGETS=go1.16 go1.17
ARM_TARGETS=go1.16 go1.17
# TODO: to be replaced once we validate it works as expected
# TODO: version to be tagged too.
NPCAP_VERSION=1.60
#NPCAP_FILE=npcap-$(NPCAP_VERSION)-oem.exe
NPCAP_FILE=test.txt

export NPCAP_VERSION

# Requires login at google storage.
copy-npcap: status=".status.copy-npcap"
copy-npcap:
ifeq ($(CI),true)
	@echo '0' > ${status}
	$(foreach var,$(TARGETS), \
		gsutil cp gs://obs-ci-cache/private/$(NPCAP_FILE) $(var)/npcap/lib/$(NPCAP_FILE) || echo '1' > ${status})
else
	@echo 'Only available if running in the CI'
endif

build: status=".status.build"
build:
	@echo '0' > ${status}
	@$(foreach var,$(TARGETS), \
		$(MAKE) -C $(var) $@ || echo '1' > ${status}; \
		$(MAKE) -C $(var) -f Makefile.debian7 $@ || echo '1' > ${status}; \
		$(MAKE) -C $(var) -f Makefile.debian8 $@ || echo '1' > ${status}; \
		$(MAKE) -C $(var) -f Makefile.debian9 $@ || echo '1' > ${status}; \
		$(MAKE) -C $(var) -f Makefile.debian10 $@ || echo '1' > ${status})
	@make -C fpm $@ || echo '1' > ${status}
	exit $$(cat ${status})

build-arm: status=".status.build.arm"
build-arm:
	echo '0' > ${status}
	$(foreach var,$(ARM_TARGETS), \
		$(MAKE) -C $(var) $@ || echo '1' > ${status};\
		$(MAKE) -C $(var) -f Makefile.debian9 $@ || echo '1' > ${status})
	make -C fpm $@ || echo '1' > ${status}
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
		$(MAKE) -C $(var) -f Makefile.debian10 $@ || echo '1' > ${status})
	@make -C fpm $@ || echo '1' > ${status}
	exit $$(cat ${status})

push-arm: status=".status.push.arm"
push-arm:
	@echo '0' > ${status}
	@$(foreach var,$(ARM_TARGETS), \
		$(MAKE) -C $(var) $@ || echo '1' > ${status}; \
		$(MAKE) -C $(var) -f Makefile.debian9 $@ || echo '1' > ${status})
	@make -C fpm $@ || echo '1' > ${status}
	exit $$(cat ${status})

.PHONY: build build-arm push push-arm
