include ../Makefile.common

ifeq ($(DOCKER_MULTIARCH),1)
DOCKER_CMD := $(SELF_DIR)/../.buildkite/scripts/buildx.sh

push:
	@echo "Already done by buildx (.buildkite/scripts/buildx.sh)."
atomic-push:
	@echo "Already done by buildx (.buildkite/scripts/buildx.sh)."
endif

ifeq ($(BUILDX)$(DEBIAN_VERSION),19)
DOCKER_CMD := $(SELF_DIR)/../.buildkite/scripts/buildx.sh

push:
	@echo "Already done by buildx (.buildkite/scripts/buildx.sh)."
atomic-push:
	@echo "Already done by buildx (.buildkite/scripts/buildx.sh)."
endif
