lint: ## format *.nix
	nixpkgs-fmt .

boot: ## evaluate flake for next boot
	sudo nixos-rebuild boot --flake .  --impure

switch: ## perform nixos rebuild
	sudo nixos-rebuild switch --flake . --impure

store: ## run some store cleanup
	nix store optimise
	

-include .task.cfg.mk
