{
  description = "My first flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    hyprland.url = "github:hyprwm/Hyprland";

    xdph = {
      url = "github:hyprwm/xdg-desktop-portal-hyprland";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        hyprland.follows = "hyprland";
        hyprlang.url = "github:hyprwm/hyprlang";
        hyprutils.url = "github:hyprwm/hyprutils";
        hyprwayland-scanner.url = "github:hyprwm/hyprwayland-scanner";
      };
    };

    hyprlang.url = "github:hyprwm/hyprlang";
    hyprutils.url = "github:hyprwm/hyprutils";
    hyprwayland-scanner.url = "github:hyprwm/hyprwayland-scanner";
  };

  outputs = { self, nixpkgs, home-manager, hyprland, xdph, hyprlang, hyprutils, hyprwayland-scanner, ... }:
  let
    system = "x86_64-linux";

    pkgs = import nixpkgs {
      inherit system;
      overlays = [
        hyprland.overlays.default
        hyprlang.overlays.default
        hyprutils.overlays.default
        hyprwayland-scanner.overlays.default
        (final: prev: {
          xdph = xdph.packages.${system}.default;
        })
      ];
    };
  in {
    nixosConfigurations = {
      mathieu = pkgs.lib.nixosSystem {
        inherit system;
        modules = [ ./configuration.nix ];
      };
    };
    homeConfigurations = {
      mathieu = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./home.nix ];
      };
    };
  };
}
