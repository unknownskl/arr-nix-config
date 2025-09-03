1. Create config as stated in examples/readme-module.md

2. run flake update
nix flake update --extra-experimental-features nix-command --extra-experimental-features flakes

3. run flake install
nixos-rebuild switch --flake .#nixarr