lint: ## format *.nix
	nixpkgs-fmt .

boot: ## evaluate flake for next boot
	sudo nixos-rebuild boot --flake .

switch: ## perform nixos rebuild
	sudo nixos-rebuild switch --flake .

-include .task.cfg.mk
