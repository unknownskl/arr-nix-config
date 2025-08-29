{
  description = "*Arr configuration";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

  outputs = { self, nixpkgs }:
    {
      nixosConfigurations = {
        server1 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";  # adjust if using ARM (aarch64-linux)
          modules = [
            ./hosts/common.nix
            # ./hosts/server1.nix
          ];
        };
      };
    };
}
