{ config, pkgs, ... }:

let
  zenBrowserFlake = builtins.getFlake "github:MarceColl/zen-browser-flake";
  system = "x86_64-linux";  # Replace with your system architecture, e.g., "aarch64-linux"
in
{
  environment.systemPackages = with pkgs; [
    zenBrowserFlake.packages.${system}.default
  ];
}
