{pkgs, ...}: let
  src = pkgs.fetchFromGitHub {
    owner = "respeaker";
    repo = "seeed-voicecard";
    rev = "v4.1";
    hash = "sha256-eBV9WvZXzY4U1rjLPljhWGXDOVwBeXsUwg2aV5BPB5s=";
  };
in {
  hardware.deviceTree.overlays = [
    {
      name = "seeed-2mic";
      dtsFile = "${src}/seeed-2mic-voicecard-overlay.dts";
    }
  ];
}
