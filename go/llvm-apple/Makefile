include ../Makefile.common

SUFFIX         := $(shell basename $(CURDIR))
TAG 		   := $(REPOSITORY)/$(NAME):$(SUFFIX)$(TAG_EXTENSION)

copy-npcap:
	@echo "NOOP"

build:
	@echo ">> Building $(TAG)"
	@go run $(SELF_DIR)/../template.go -t Dockerfile.tmpl -o Dockerfile
	@docker build -t "$(TAG)" \
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
	@echo ">> Pushing $(REPOSITORY)/$(NAME):$(TAG)"
	@docker push "$(REPOSITORY)/$(NAME):$(TAG)"
