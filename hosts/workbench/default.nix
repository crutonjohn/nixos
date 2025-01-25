{ config, lib, nixpkgs, pkgs, inputs, ... }:

{
  imports = [

    ./minio
    ./podman

    inputs.nixos-hardware.nixosModules.common-pc-ssd
    ./desktop.nix
    ./fonts.nix
    ./greeter.nix
    ./hardware-configuration.nix
    ./hardware.nix
    ./vm-hook.nix
    ./loader.nix
    ./networking.nix
    ./nginx.nix
    ./virtualization.nix
    ./vm-hook.nix
    ./zfs.nix
  ];

  time.timeZone = "America/New_York";

  # SSH Server
  services.openssh.enable = true;

  # Enable Flatpak
  services.flatpak.enable = true;

  system.stateVersion = "24.05";

}