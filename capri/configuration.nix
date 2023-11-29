{ pkgs, ... }:
let
  common = import ../common.nix;
in
{
  imports =
    [
      ./hardware-configuration.nix
      common.config
    ];
  #nix.registry.nixpkgs.flake = nixpkgs;
  #nix.package = pkgs.nixFlakes;

  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.luks.devices = {
    crypt = {
      device = "/dev/disk/by-uuid/4b6c70d3-8d32-4dd1-acfc-ae1b73c67797";
      preLVM = true;
      allowDiscards = false;
    };
  };


  networking.proxy.default = common.proxy "julius9dev9gemini1" "7049740682";
  networking.interfaces.eth0.ipv4.addresses = [{
    address = "10.38.90.22";
    prefixLength = 24;
  }];
  networking.defaultGateway = "10.38.90.1";
  networking.hostName = "capri";
  networking.dhcpcd.enable = true;

  users.users.julius = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = common.sshKeys.client;
    packages = with pkgs; [
      fish
      nushell
      helix
      git
      gh
    ];
    shell = pkgs.nushell;
    password = "";
  };

  environment.systemPackages = common.packages pkgs;
  #programs.direnv.nix-direnv.enable = true; TODO: IDGI

  services.acpid.enable = true; # 2023-11-17 Might prevent shutdown hang - todo test
  virtualisation.vmware.guest.enable = true;

  networking.firewall.allowedTCPPorts = [ 2222 1337 ];
  networking.firewall.allowedUDPPorts = [ ];
  networking.firewall.enable = true;

  #system.copySystemConfiguration = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

  #fileSystems."/boot" =
  #  { device = "/dev/disk/by-label/boot";
  #    fsType = "vfat";
  #  };
}

