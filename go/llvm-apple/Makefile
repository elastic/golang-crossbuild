include ../Makefile.common

SUFFIX         := $(shell basename $(CURDIR))
TAG 		   := $(REPOSITORY)/$(NAME):$(SUFFIX)$(TAG_EXTENSION)

ifeq ($(DOCKER_MULTIARCH),1)
DOCKER_CMD := $(SELF_DIR)/../.ci/scripts/buildx.sh

push:
	@echo "Already done by buildx (.ci/scripts/buildx.sh)."
atomic-push:
	@echo "Already done by buildx (.ci/scripts/buildx.sh)."
endif

copy-npcap:
	@echo "NOOP"

build:
	@echo ">> Building $(TAG)"
	@go run $(SELF_DIR)/../template.go -t Dockerfile.tmpl -o Dockerfile
	@$(DOCKER_CMD) -t "$(TAG)" \
	--build-arg REPOSITORY=$(REPOSITORY) \
	--build-arg VERSION=$(VERSION) \
	--build-arg DEBIAN_VERSION=$(DEBIAN_VERSION) \
	--build-arg TAG_EXTENSION=$(TAG_EXTENSION) \
	--build-arg IMAGE="$(TAG)" \
	--build-arg VCS_REF="$(VCS_REF)" \
	--build-arg VCS_URL="$(VCS_URL)" \
	--build-arg BUILD_DATE="$(BUILD_DATE)" \
	.

atomic-push:
	@echo ">> Pushing $(TAG)"
	@docker push "$(TAG)"
