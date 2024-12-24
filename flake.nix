{

  description = "My first flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    superfile = {
      url = "github:yorukot/superfile";
    };

    rose-pine-hyprcursor.url = "github:ndom91/rose-pine-hyprcursor";
  };

  outputs = { self, nixpkgs, home-manager, ... } @inputs:
  let 
    lib = nixpkgs.lib;
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system}; 
  in {
    nixosConfigurations.mathieu = lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        
        modules = [
          ./configuration.nix 
        ];
      
      };
    # };

    homeConfigurations = {
      mathieu = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ 
          ./home.nix
        ];
      };      
    };
  };
}
