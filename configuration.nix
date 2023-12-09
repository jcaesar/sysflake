{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ 
       "${modulesPath}/installer/scan/not-detected.nix"

    ];

  # Use the systemd-boot EFI boot loader.
  #boot.loader.systemd-boot.enable = true;
  #boot.loader.efi.canTouchEfiVariables = true;

  boot.loader.grub = {
    enable = true;
    zfsSupport = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    mirroredBoots = [
      { devices = [ "nodev"]; path = "/boot"; }
    ];
  };

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid"  "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "nixpool/root";
      fsType = "zfs";
    };

  fileSystems."/nix" =
    { device = "nixpool/nix";
      fsType = "zfs";
    };

  fileSystems."/var" =
    { device = "nixpool/var";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "nixpool/home";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-label/nixboot";
      fsType = "vfat";
    };

  swapDevices = [ ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = false;
  # networking.interfaces.enp5s0.useDHCP = lib.mkDefault true;
systemd.network.enable = true;
networking.interfaces.eth0.ipv4.addresses = [ {
  address = "10.13.52.20";
  prefixLength = 24;
} ];


networking.defaultGateway = {
  address = "10.13.52.1";
  interface = "enp5s0";
};

  

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;

  networking.hostName = "pride"; # Define your hostname.
  networking.hostId = "7ef47bc5";
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "Asia/Tokyo";


  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
     # nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
     #        "nvidia-x11-545.29.06-6.1.65"
     #      ];
 nixpkgs.config.allowUnfree = true;
         


  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  hardware.pulseaudio.enable = false;
security.rtkit.enable = true;
services.pipewire = {
  enable = true;
  alsa.enable = true;
  alsa.support32Bit = true;
  pulse.enable = true;
  # If you want to use JACK applications, uncomment this
  #jack.enable = true;
};


  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.julius = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      firefox
      tree

    ];
  };
  users.users.root.openssh.authorizedKeys.keys = [
    "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAAqmN0bQWftRFvSCFRmIct6nvwoosuX3hqfp+4uKhUdDxDOThqqqturJUEpovz6Jb/p9nQPee+hMkCMDmpNIEPTKgDaD+MY58tX3bcayHBAoGPyY+RMOaEvHQ+AWjicVqE7Yo9E27sbELIbp0p9QSGDYTaN690ap7KjpoyhlpAvOkV++Q== julius"
  ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    helix
    git
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "23.11"; # Did you read the comment?

}

