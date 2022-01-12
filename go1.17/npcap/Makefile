include ../Makefile.common

SUFFIX = $(SUFFIX_NPCAP_VERSION)

push:
	@[ "$(REPOSITORY)" = "$(NPCAP_REPOSITORY)" ] \
	&& $(MAKE) atomic-push \
	|| echo "WARNING: $(SUFFIX_NPCAP_VERSION) can only be published in $(NPCAP_REPOSITORY)"
