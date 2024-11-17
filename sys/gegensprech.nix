{
  pkgs,
  lib,
  ...
}: let
  private = import ../private.nix;
in {
  njx.pi3 = true;
  njx."seeed-2mic/default" = true;
  njx.sshUnlock.keys = private.terminalKeys;
  boot.initrd.systemd.enable = true;
  networking.hostName = "gegensprech";
  networking.supplicant.wlan0.extraConf = "country=JP";
  users.users.root.openssh.authorizedKeys.keys = private.terminalKeys ++ [private.prideKey];
  users.users.gegensprech = {
    isNormalUser = true;
    packages = with pkgs; [gegensprech mpv];
    openssh.authorizedKeys.keys = private.terminalKeys;
    linger = true;
    extraGroups = ["gpio"];
  };
  home-manager.users.gegensprech.systemd.user.services.gegensprech = {
    Unit.Description = "Gegensprech";
    Service.ExecStart = "${lib.getExe pkgs.gegensprech} run seeed-2mic";
    Service.Environment = "RUST_LOG=info,gegensprech=warn";
    Install.WantedBy = ["default.target"];
  };
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  environment.systemPackages = with pkgs; [alsa-utils dtc libraspberrypi];
  boot.initrd.systemd.services.blinky = {
    unitConfig.DefaultDependencies = false;
    serviceConfig.ExecStart = lib.getExe pkgs.seeed-2mic-blinky;
    wantedBy = ["local-fs.target"];
  };

  documentation.enable = false;
  system.stateVersion = "24.05";
  home-manager.users.gegensprech.home.stateVersion = "24.05";
}
