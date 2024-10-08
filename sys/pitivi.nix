{
  pkgs,
  lib,
  ...
}: let
  private = import ../private.nix;
in {
  njx.pi3 = true;
  njx.dlna = true;
  njx.sshUnlock.keys = private.terminalKeys;
  networking.hostName = "pitivi";
  networking.supplicant.wlan0.extraConf = "country=JP";

  systemd.network = {
    enable = true;
    networks."12-wired" = {
      matchConfig.Name = ["enu1u1"];
      linkConfig.RequiredForOnline = false;
      DHCP = "yes";
    };
  };

  users.users.root.openssh.authorizedKeys.keys = private.terminalKeys ++ [private.prideKey];
  users.users.media = {
    isNormalUser = true;
    packages = with pkgs; [mpv];
    shell = pkgs.nushell;
    openssh.authorizedKeys.keys = private.terminalKeys;
  };
  environment.systemPackages = with pkgs; [libcec];

  services.home-assistant = {
    enable = true;
    extraComponents = [
      "met"
      "radio_browser"
      "media_player"
      "zha"
      "bluetooth_tracker"
      "bluetooth_le_tracker"
      "bluetooth"
      "bluetooth_adapters"
      "generic_thermostat"
      "dhcp"
    ];
    config = {
      default_config = {};
    };
  };

  documentation.enable = false;
  system.stateVersion = "24.05";
}
