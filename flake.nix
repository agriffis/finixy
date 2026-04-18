{
  description = "NixOS configuration with Flakes and Framework support";

  inputs = {
    # NixOS official package source
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Hardware specific tweaks
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = { self, nixpkgs, nixos-hardware, ... }@inputs: {
    nixosConfigurations.wren = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./configuration.nix
        # The specific Framework 13 AMD 7040 module
        nixos-hardware.nixosModules.framework-13-7040-amd
      ];
    };
  };
}
