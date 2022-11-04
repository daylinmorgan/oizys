switch:
	sudo nixos-rebuild switch --flake . --impure

lint:
	nixpkgs-fmt .

.PHONY: lint
