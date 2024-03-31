{ name, nodes, pkgs, lib, inputs, config, ... }:

let
  baremetalblogSrc = pkgs.fetchgit {
    url = "https://github.com/crutonjohn/baremetalblog.git";
    rev = "76614fb2b74ebb5f2b0e7e17bfe18b5a756c06eb";
    sha256 = "sha256-EVC/4Vmqk/Yub8x5hD2jv0+eWcrn1KLo4UmXecfd8A0=";
    fetchSubmodules = true;
  };

  baremetalblog = pkgs.stdenv.mkDerivation rec {
    name = "baremetalblog";
    src = baremetalblogSrc;
    buildPhase =
    ''
      ls -al themes/hello-friend
      mkdir -p $out
      ${pkgs.hugo}/bin/hugo --minify --noBuildLock -t hello-friend -d $out/
    '';
  };

in

{

services.nginx = {
  enable = true;
  recommendedProxySettings = true;
  recommendedTlsSettings = true;
  logError = "stderr info";
};

users.users.nginx.extraGroups = [ "acme" ];
security.acme = {
  acceptTerms = true;
  defaults.email = "certs+crutonjohn@pm.me";
};

services.nginx.virtualHosts = {
  "baremetalblog.com" = {
    useACMEHost = "baremetalblog.com";
    forceSSL = true;
    root = "${baremetalblog}";
    locations."/" = {
      tryFiles = "$uri $uri/ =404";
      index = "index.html";
    };
  };
  "www.baremetalblog.com" = {
    locations."/" = {
      return = "301 https://baremetalblog.com$request_uri";
    };
  };
};

sops = {
  secrets."acme/linode/credentials" = {
    mode = "0440";
    group = "nginx";
    owner = "acme";
  };
};

security.acme.certs = {
  "baremetalblog.com" = {
    dnsProvider = "linode";
    # linode ns1
    dnsResolver = "162.159.27.72:53";
    enableDebugLogs = true;
    # https://go-acme.github.io/lego/dns/linode/
    #credentialsFile = "/var/lib/acme/linode/credentials";
    # secret handled by sops now
    credentialsFile = "/run/secrets/acme/linode/credentials";
    extraDomainNames = [
      #"www.baremetalblog.com"
    ];
    group = "nginx";
  };
};


## integrate flake changes in this repo to main flake repo
## rename `nixos` repo to something else like `dootfiles` or maybe some other cool video game lore thing
## potentially create github action to keep blog up-to-date? re-deploy nightly?
## deploy site changes on push to main

}
