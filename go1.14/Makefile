IMAGES := base i386 amd64 darwin arm64 armel armhf mips mips64 mipsel mips64el ppc64 ppc64el s390x

build:
	@$(foreach var,$(IMAGES),$(MAKE) -C $(var) build || exit 1;)

# Requires login at https://docker.elastic.co:7000/.
push:
	@$(foreach var,$(IMAGES),$(MAKE) -C $(var) push || exit 1;)

.PHONY: build push
