# mips ppc s390x are temporarily disabled. See: https://github.com/elastic/golang-crossbuild/issues/71
IMAGES := base main darwin arm

build:
	@$(foreach var,$(IMAGES),$(MAKE) -C $(var) build || exit 1;)

# Requires login at https://docker.elastic.co:7000/.
push:
	@$(foreach var,$(IMAGES),$(MAKE) -C $(var) push || exit 1;)

.PHONY: build push
