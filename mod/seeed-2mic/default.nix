{...}: {
  hardware.deviceTree = {
    filter = "*2837-rpi-zero-2-w*";
    overlays = [
      {
        name = "seeed-2mic";
        dtsFile = ./seeed-2mic-voicecard-overlay.dts;
      }
    ];
  };
}
