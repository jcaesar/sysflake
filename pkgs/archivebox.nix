# nixpkgs uses current release, has CVEs assigned that I don't trust are irrelevant
pkgs: let
  ppkgs = pkgs.python3.pkgs;
  callPackage = ppkgs.callPackage;
  buildPypiPackage = attrs:
    ppkgs.buildPythonPackage (attrs
      // {
        src = ppkgs.fetchPypi {
          inherit (attrs) pname version;
          hash = attrs.srcHash;
        };
      });
  django-settings-holder = callPackage ({
    django_5,
    poetry-core,
  }:
    buildPypiPackage {
      pname = "django_settings_holder";
      version = "0.1.2";
      srcHash = "sha256-irDy2r9aHHnsnpXpeiloCODyxI9vmqHaG3e0M+4eL54=";
      format = "pyproject";
      nativeBuildInputs = [poetry-core];
      propagatedBuildInputs = [django_5];
    }) {};
  django-signal-webhooks = callPackage ({
    django_5,
    poetry-core,
    cryptography,
    httpx,
  }:
    buildPypiPackage {
      pname = "django_signal_webhooks";
      version = "0.3.0";
      srcHash = "sha256-Pv/0MFqMBVWhfOj0y7EAYBSv1zFIYmR9tXJOBu7EST4=";
      format = "pyproject";
      nativeBuildInputs = [poetry-core];
      propagatedBuildInputs = [django_5 cryptography httpx django-settings-holder];
    }) {};
  django-admin-data-views = callPackage ({
    django_5,
    poetry-core,
  }:
    buildPypiPackage {
      pname = "django_admin_data_views";
      version = "0.3.1";
      srcHash = "sha256-NHojWNOaD9Dg5GjxihS+OpgBiUt/j0Cz2kdSDzpDT4Y=";
      format = "pyproject";
      nativeBuildInputs = [poetry-core];
      propagatedBuildInputs = [django_5 django-settings-holder];
    }) {};
  django-extensions = ppkgs.django-extensions.override {django = ppkgs.django_5;};
  django-ninja = ppkgs.django-ninja.override {django = ppkgs.django_5;};
in
  pkgs.archivebox.overrideAttrs (old: {
    src = pkgs.fetchFromGitHub {
      owner = "ArchiveBox";
      repo = "ArchiveBox";
      rev = "102e87578c6036bb0132dd1ebd17f8f05ffc880f";
      hash = "sha256-Kmmieis8Fzl07VIIuxlpkhLXx9uoMDZx8BVIfLtKlYM=";
    };
    propagatedBuildInputs =
      [
        pkgs.yt-dlp
        django-signal-webhooks
        django-extensions
        django-ninja
        django-admin-data-views
      ]
      ++ (with pkgs.python3.pkgs; [
        croniter
        dateparser
        django_5
        feedparser
        ipython
        mypy-extensions
        python-crontab
        requests
        setuptools
        w3lib
      ]);

    # map (inp: let
    #   remVul = lib.flip (lib.foldr lib.remove) [
    #     "CVE-2021-45115"
    #     "CVE-2021-45116"
    #     "CVE-2021-45452"
    #     "CVE-2022-23833"
    #     "CVE-2022-22818"
    #     "CVE-2022-28347"
    #     "CVE-2022-28346"
    #   ];
    #   cleanMeta = inp.meta // {knownVulnerabilities = remVul (inp.meta.knownVulnerabilities or []);};
    #   meta =cleanMeta;      in
    #   inp.overrideAttrs {inherit meta;})
    # old.propagatedBuildInputs;
  })
