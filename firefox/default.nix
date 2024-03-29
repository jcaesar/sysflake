# https://discourse.nixos.org/t/declare-firefox-extensions-and-settings/36265
let
  lock = Value: {
    inherit Value;
    Status = "locked";
  };
in
  {
    pkgs,
    lib,
    ...
  }: {
    programs = {
      firefox = {
        package = pkgs.firefox-devedition;
        enable = true;
        languagePacks = ["en-GB" "de" "ja"];

        # ---- POLICIES ----
        # Check about:policies#documentation or https://mozilla.github.io/policy-templates/
        policies = {
          DisableTelemetry = true;
          DisableFirefoxStudies = true;
          EnableTrackingProtection = {
            Value = true;
            Locked = true;
            Cryptomining = true;
            Fingerprinting = true;
          };
          DisablePocket = true;
          DisableFirefoxAccounts = true;
          DisableAccounts = true;
          DisableFirefoxScreenshots = true;
          DisableSetDesktopBackground = true;
          OverrideFirstRunPage = "";
          OverridePostUpdatePage = "";
          DontCheckDefaultBrowser = true;
          DisplayBookmarksToolbar = "never";
          DisplayMenuBar = "default-off";
          SearchBar = "separate";

          # ---- EXTENSIONS ----
          # cat ~/.mozilla/firefox/*.default/addons.json | from json
          # | get addons | select name id sourceURI
          # | each {|addon| update sourceURI ($addon.sourceURI | str replace --regex '/[^/]*.xpi' '/latest.xpi')}
          # | save addons.json
          # Alternatively: Check about:support for extension/add-on ID strings.
          ExtensionSettings = builtins.listToAttrs (map (ex: {
              name = ex.id;
              value = {
                install_url = ex.sourceURI;
                installation_mode = "normal_installed";
              };
            }) (
              lib.importJSON ./addons.json
              ++ map (ex: let
                src = pkgs.fetchFromGitHub {
                  owner = "jcaesar";
                  repo = "rowserext";
                  rev = "f8a1cfbcc7e5376c65bce31c0204b93243b949ec";
                  hash = "sha256-H4LV2t2kjAb4YvIOR8RqryMKvhWxjMi/16Nkhu7Ny/o=";
                };
                build = pkgs.callPackage src {};
              in {
                id = "rowserext-${ex}@liftm.de";
                sourceURI = "file://${build}/${ex}.xpi";
              }) ["lionel" "join-on-time"]
            ));

          # ---- PREFERENCES ----
          Preferences = {
            "browser.contentblocking.category" = lock "strict";
            "extensions.pocket.enabled" = lock false;
            "browser.topsites.contile.enabled" = lock false;
            #"browser.formfill.enable" = lock false;
            "browser.search.suggest.enabled" = lock false;
            "browser.search.suggest.enabled.private" = lock false;
            "browser.urlbar.suggest.searches" = lock false;
            "browser.urlbar.showSearchSuggestionsFirst" = lock false;
            "browser.newtabpage.activity-stream.feeds.section.topstories" = lock false;
            "browser.newtabpage.activity-stream.feeds.snippets" = lock false;
            "browser.newtabpage.activity-stream.section.highlights.includePocket" = lock false;
            "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = lock false;
            "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = lock false;
            "browser.newtabpage.activity-stream.section.highlights.includeVisited" = lock false;
            "browser.newtabpage.activity-stream.showSponsored" = lock false;
            "browser.newtabpage.activity-stream.system.showSponsored" = lock false;
            "browser.newtabpage.activity-stream.showSponsoredTopSites" = lock false;
            "browser.sessionstore.warnOnQuit" = true;
            "xpinstall.signatures.required" = lock false; # Meh, can't install my custom extensions otherwise. only works on esr/devedition
          };
        };
      };
    };
  }
