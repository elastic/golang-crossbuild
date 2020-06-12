IMAGES := base amd64 i386 darwin arm mips ppc s390x

build:
	@$(foreach var,$(IMAGES),$(MAKE) -C $(var) build || exit 1;)

# Requires login at https://docker.elastic.co:7000/.
push:
	@$(foreach var,$(IMAGES),$(MAKE) -C $(var) push || exit 1;)

.PHONY: build push
