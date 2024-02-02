{pkgs, ...}: {
  systemd.services."nvml-prometheus-exporter" = {
    wantedBy = ["multi-user.target"];
    after = ["network.target"];
    serviceConfig = {
      ExecStart = "${((import ./pkgs/nvml-prometheus-exporter.nix) pkgs)}/bin/nvml-prometheus-exporter";
      PrivateTmp = true;
      WorkingDirectory = /tmp;
      DynamicUser = true;
      User = "nvml-prometheus-exporter";
      CapabilityBoundingSet = [""];
      #DeviceAllow = ["char-nvidia* r"];
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      #PrivateDevices = true;
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectSystem = "strict";
      RemoveIPC = true;
      RestrictAddressFamilies = ["AF_INET" "AF_INET6"];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      SystemCallArchitectures = "native";
      UMask = "0077";
    };
  };
}
