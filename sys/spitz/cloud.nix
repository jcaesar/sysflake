{config, pkgs, ...}: {
  services.mysql.enable = true;
  services.mysql.package = pkgs.mariadb;
  services.nextcloud = {
    enable = false;
    hostName = "cloud.liftm.de";
    https = true;
    database.createLocally = true;
    config.dbtype = "mysql";
    config.adminpassFile = "/etc/secrets/nextcloud-adminpass";
    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps) contacts calendar tasks;
    };
    extraAppsEnable = true;
  };
  njx.manual.nextcloud = ''
    Create admin password file under ${config.services.nextcloud.config.adminpassFile}
    Make it be 440, owned by nextcloud:nextcloud 
  '';

  services.nginx.virtualHosts.${config.services.nextcloud.hostName} = {
    forceSSL = true;
    enableACME = true;
  };
}
