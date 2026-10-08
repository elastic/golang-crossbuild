include ../Makefile.common

SUFFIX = $(SUFFIX_NPCAP_ARM64_VERSION)
NPCAP_LIB_DIR := lib

push-arm:
	@[ "$(REPOSITORY)" = "$(NPCAP_REPOSITORY)" ] \
	&& $(MAKE) atomic-push \
	|| echo "WARNING: $(SUFFIX_NPCAP_ARM64_VERSION) can only be published in $(NPCAP_REPOSITORY)"
