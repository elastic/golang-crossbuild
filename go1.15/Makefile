IMAGES := base main darwin arm mips ppc s390x
ARM_IMAGES := base-arm main

build:
	@$(foreach var,$(IMAGES),$(MAKE) -C $(var) build || exit 1;)

build-arm:
	@$(foreach var,$(ARM_IMAGES),$(MAKE) -C $(var) build-arm || exit 1;)

# Requires login at https://docker.elastic.co:7000/.
push:
	@$(foreach var,$(IMAGES),$(MAKE) -C $(var) push || exit 1;)

push-arm:
	@$(foreach var,$(ARM_IMAGES),$(MAKE) -C $(var) push-arm || exit 1;)

.PHONY: build build-arm push push-arm
