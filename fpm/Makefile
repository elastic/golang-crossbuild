include ../Makefile.common

NAME    := fpm
VERSION := 1.13.1

build:
	@echo ">> Building $(REPOSITORY)/$(NAME):$(VERSION)$(SUFFIX)"
	@go run ../template.go -t Dockerfile.tmpl -o Dockerfile
	@docker run --privileged --rm tonistiigi/binfmt:v9.2.2 --install all

	@docker buildx ls
	@echo 'Create builder'
	@docker buildx create --name "multiarchcontext"
	@docker buildx use "multiarchcontext"
	@docker buildx inspect --bootstrap
	@echo 'Build Docker image'
	@docker buildx build --progress=plain --platform "linux/amd64,linux/arm64" -t "$(REPOSITORY)/$(NAME):$(VERSION)$(SUFFIX)" \
	--build-arg FPM_VERSION=$(VERSION) \
	--build-arg IMAGE="$(REPOSITORY)/$(NAME):$(VERSION)$(SUFFIX)$(TAG_EXTENSION)" \
	--build-arg VCS_REF="$(VCS_REF)" \
	--build-arg VCS_URL="$(VCS_URL)" \
	--build-arg BUILD_DATE="$(BUILD_DATE)" \
	--push .

.PHONY: build
