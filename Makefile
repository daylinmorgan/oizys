boot:
	sudo nixos-rebuild boot --flake .

## switch | perform nixos rebuild
switch:
	sudo nixos-rebuild switch --flake .
	
## lint | format *.nix
lint:
	nixpkgs-fmt .

.PHONY: lint switch boot

USAGE := {a.style('==>','bold')} {a.style('flakes ftw','header')} {a.style('<==','bold')}\n
-include .task.mk
$(if $(filter help,$(MAKECMDGOALS)),$(if $(wildcard .task.mk),,.task.mk: ; curl -fsSL https://raw.githubusercontent.com/daylinmorgan/task.mk/v22.9.28/task.mk -o .task.mk))
