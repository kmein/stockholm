ifndef system
$(error unbound variable: system)
endif

export target_host ?= $(system)
export target_user ?= root
export target_path ?= /var/src

evaluate = \
	nix-instantiate \
		--arg configuration ./$(LOGNAME)/1systems/$(system).nix \
		--eval \
		--readonly-mode \
		--show-trace \
		$(1)

execute = \
	result=$$($(call evaluate,-A config.krebs.build.$(1) --json)) && \
	script=$$(echo "$$result" | jq -r .) && \
	echo "$$script" | sh

# usage: make deploy system=foo [target_host=bar]
deploy:
	$(call execute,populate)
	ssh $(target_user)@$(target_host) nixos-rebuild switch -I $(target_path)

# usage: make LOGNAME=shared system=wolf eval.config.krebs.build.host.name
eval eval.:;@$(call evaluate)
eval.%:;@$(call evaluate,-A $*)

# usage: make install system=foo [target_host=bar]
install: ssh ?= ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
install:
	$(ssh) $(target_user)@$(target_host) \
		env target_path=$(target_path) \
			sh -s prepare < krebs/4lib/infest/prepare.sh
	target_path=/mnt$(target_path) $(call execute,populate)
	$(ssh) $(target_user)@$(target_host) \
		env NIXOS_CONFIG=$(target_path)/nixos-config \
			nixos-install
