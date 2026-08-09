{
  description = "NixOS configuration with Framework support";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    mangowm = {
      url = "github:mangowm/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    firefox-nightly.url = "github:nix-community/flake-firefox-nightly";
    mise.url = "github:jdx/mise";
  };

  outputs = { self, nixpkgs, nixos-hardware, mise, ... }@inputs: {
    nixosConfigurations.wren = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        { nixpkgs.overlays = [ (_final: _prev: { mise = mise.packages.x86_64-linux.mise; }) ]; }
        ./configuration.nix
        nixos-hardware.nixosModules.framework-13-7040-amd
        inputs.mangowm.nixosModules.mango
        ./noctalia.nix
      ];
    };
  };
}
