include ../Makefile.common

NAME    := fpm
VERSION := 1.11.0

build:
	@echo ">> Building $(REPOSITORY)/$(NAME):$(VERSION)$(SUFFIX)"
	@docker build -t "$(REPOSITORY)/$(NAME):$(VERSION)$(SUFFIX)" \
	--build-arg FPM_VERSION=$(VERSION) \
	--build-arg IMAGE="$(REPOSITORY)/$(NAME):$(VERSION)$(SUFFIX)$(TAG_EXTENSION)" \
	--build-arg VCS_REF="$(VCS_REF)" \
	--build-arg VCS_URL="$(VCS_URL)" \
	--build-arg BUILD_DATE="$(BUILD_DATE)" \
	.

.PHONY: build
