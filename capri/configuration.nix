{ pkgs, ... }:
let
  common = import ../common.nix;
in
{
  imports = [
    ./hardware-configuration.nix
    common.config
  ];

  boot.initrd.luks.devices = {
    crypt = {
      # cryptsetup conrig /dev/foo --label crypt
      device = "/dev/disk/by-label/crypt";
      preLVM = true;
      allowDiscards = false;
    };
  };

  # Stage 1 ssh decrypt. Several things about this are dumb
  #  - Somehow, it includes the /etc/ssh/boot in the initrd, but I have no idea how
  #  - It does not automatically pick up on the network configuration
  #  - Need to specify the driver manually
  #  - The password is entered with "echo pw >/crypt-ramfs/passphrase" (that's not a pipe, its a file that's checked once per second)
  boot.initrd.kernelModules = [ "e1000" ];
  boot.initrd.network.enable = true;
  boot.initrd.network.ssh = {
    enable = true;
    port = 2223;
    hostKeys = [
      "/etc/ssh/boot/host_rsa_key"
      "/etc/ssh/boot/host_ed25519_key"
    ];
    authorizedKeys = common.sshKeys.strong;
  };
  boot.kernelParams = [
    "ip=10.38.90.22::10.38.90.1:255.255.255.0:capri:eth0:off" # Bit stupid that this isn't taken from networking.interfaces.…
    # Debugging init: "boot.trace" "boot.debugtrace" "debug1"
  ];

  networking.proxy.default = common.proxy "julius9dev9gemini1" "7049740682";
  networking.interfaces.eth0.ipv4.addresses = [{
    address = "10.38.90.22";
    prefixLength = 24;
  }];
  networking.defaultGateway = {
    address = "10.38.90.1";
    interface = "eth0";
  };
  networking.hostName = "capri";

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

  services.acpid.enable = true; # Was supposed to prevent shutdown hang, doesn't
  virtualisation.vmware.guest.enable = true;

  networking.firewall.allowedTCPPorts = [ 2222 2223 1337 ];
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

