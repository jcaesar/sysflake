{
  lib,
  pkgs,
  ...
}: {
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
  boot.binfmt.emulatedSystems = ["aarch64-linux" "wasm32-wasi" "wasm64-wasi"];
  programs.java.binfmt = true;
  programs.nix-ld.enable = true;

  users.users.yamaguchi = {
    uid = 1006;
    isNormalUser = true;
    linger = true;
    extraGroups = ["wheel"];
    openssh.authorizedKeys.keys = (import ../work.nix).sshKeys.yamaguchi;
    packages = with pkgs; [
      fish
      helix
      git
      gh
      file
      unar
      delta
      rsync
      difftastic
      sshfs
      pwgen
      binutils
      binwalk
      bat
      #jupyter-all # Somehow, jupyter works anyway. No idea how
      conda
      micromamba
      gh
      openvscode-server
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
          jupyter-book
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
          python-jsonrpc-server
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
    ];
    password = "";
    shell = pkgs.bash;
  };
}
