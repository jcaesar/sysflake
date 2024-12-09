let
  keys = (import ../work.nix).sshKeys;
in
  {
    lib,
    pkgs,
    config,
    ...
  }: {
    njx.common = true;
    njx.binfmt = true;
    assertions = [
      {
        assertion = let
          vscodeNode = lib.findSingle (x: x.pname or "" == "nodejs") (throw "no nodejs") (throw "more than one nodejs") pkgs.openvscode-server.nativeBuildInputs;
        in
          !lib.versionAtLeast vscodeNode.version "19.0.0";
        message = "openvscode-server is good again. readd and delete assertion.";
      }
    ];

    # Not for now
    services.kubernetes = {
      roles = lib.mkForce [];
      easyCerts = lib.mkForce false;
    };

    fileSystems."/home" = {
      device = "/dev/mapper/centos_shamox-home";
      fsType = "xfs";
    };

    virtualisation.docker = {
      enable = true;
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
    };
    programs.java.binfmt = true;
    programs.nix-ld.enable = true;

    services.ollama.enable = true;
    services.ollama.environmentVariables = {
      OLLAMA_KEEP_ALIVE = "1h";
      OLLAMA_MAX_LOADED_MODELS = "5";
    };

    users.users.yamaguchi = {
      uid = 1006;
      isNormalUser = true;
      linger = true;
      extraGroups = ["wheel"];
      openssh.authorizedKeys.keys = keys.yamaguchi;
      packages =
        (with pkgs; [
          #jupyter-all # Somehow, jupyter works anyway. No idea how
          # conda # license doubts - conda itself is fine, the stuff it downloads might not be
          micromamba
          #openvscode-server # depends on EOL nodejs
          (python3.withPackages (ps:
            with ps; [
              # descartes
              # TODO?: asv larch openmatrix pypyr sharrow sphinx-autosummary-accessors xmle
              aiohttp
              black
              bump2version
              coveralls
              cytoolz
              dask
              filelock
              fsspec
              geopandas
              grpcio
              grpcio-health-checking
              grpcio-reflection
              iniconfig
              ipykernel
              isort
              jupyter
              # jupyter-book # todo
              jupyterlab
              mamba
              matplotlib
              myst-parser
              nbconvert
              nbformat
              netaddr
              numba
              numexpr
              numpy
              numpydoc
              orca
              pandas
              pip
              platformdirs
              pluggy
              pre-commit
              protobuf
              psutil
              pyarrow
              pycodestyle
              pydantic
              pydata-sphinx-theme
              pyinstrument
              tables
              pytest
              pytest-cov
              pytest-regressions
              # python-jsonrpc-server
              pyyaml
              requests
              rich
              ruby
              scikit-learn
              setuptools_scm
              snakeviz
              sphinx
              sphinx-argparse
              sphinx_rtd_theme
              tqdm
              ujson
              xarray
              zarr
            ]))
        ])
        ++ config.users.users.julius.packages;
      password = "";
      shell = pkgs.bash;
    };

    users.users.aoki = {
      uid = 1005;
      isNormalUser = true;
      linger = true;
      extraGroups = ["wheel"];
      openssh.authorizedKeys.keys = keys.aoki;
      packages = config.users.users.julius.packages;
    };

    users.users.julius.uid = 1000;
    users.users.julius.openssh.authorizedKeys.keys = keys.client;
  }
