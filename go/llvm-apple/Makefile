include ../Makefile.common

SUFFIX         := $(shell basename $(CURDIR))

copy-npcap:
	@echo "NOOP"

build:
	@echo ">> Building $(REPOSITORY)/$(NAME):$(SUFFIX)$(TAG_EXTENSION)"
	@go run $(SELF_DIR)/../template.go -t Dockerfile.tmpl -o Dockerfile
	@docker build -t "$(REPOSITORY)/$(NAME):$(SUFFIX)$(TAG_EXTENSION)" \
	--build-arg REPOSITORY=$(REPOSITORY) \
	--build-arg VERSION=$(VERSION) \
	--build-arg DEBIAN_VERSION=$(DEBIAN_VERSION) \
	--build-arg TAG_EXTENSION=$(TAG_EXTENSION) \
	--build-arg IMAGE="$(REPOSITORY)/$(NAME):$(SUFFIX)$(TAG_EXTENSION)" \
	--build-arg VCS_REF="$(VCS_REF)" \
	--build-arg VCS_URL="$(VCS_URL)" \
	--build-arg BUILD_DATE="$(BUILD_DATE)" \
