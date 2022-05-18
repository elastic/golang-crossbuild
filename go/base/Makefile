include ../Makefile.common
<<<<<<< HEAD
=======

ifeq ($(DOCKER_MULTIARCH),1)
DOCKER_CMD := $(SELF_DIR)/../.ci/scripts/buildx.sh

push:
	@echo "Already done by buildx (.ci/scripts/buildx.sh)."
atomic-push:
	@echo "Already done by buildx (.ci/scripts/buildx.sh)."
endif

ifeq ($(BUILDX)$(DEBIAN_VERSION),19)
DOCKER_CMD := $(SELF_DIR)/../.ci/scripts/buildx.sh

push:
	@echo "Already done by buildx (.ci/scripts/buildx.sh)."
atomic-push:
	@echo "Already done by buildx (.ci/scripts/buildx.sh)."
endif
>>>>>>> 603a052 (feat: build arm64 Docker image for amd64/arm64 (#201))
