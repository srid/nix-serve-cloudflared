{ config, lib, pkgs, ... }:

let
  cfg = config.services.nix-serve-cloudflared;
in
{
  options.services.nix-serve-cloudflared = {
    enable = lib.mkEnableOption "Nix binary cache server with Cloudflare tunnel";

    port = lib.mkOption {
      type = lib.types.port;
      default = 5000;
      description = "Port for nix-serve-ng to listen on";
    };

    secretKeyFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to the cache signing key file";
      example = "/run/agenix/nix-serve-cloudflared/cache-key.pem";
    };

    cloudflare = {
      tunnelId = lib.mkOption {
        type = lib.types.str;
        description = "Cloudflare tunnel ID";
      };

      credentialsFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to Cloudflare tunnel credentials file";
        example = "/run/agenix/nix-serve-cloudflared/cloudflared-credentials.json";
      };

      domain = lib.mkOption {
        type = lib.types.str;
        description = "Domain name for the Nix cache";
        example = "cache.example.com";
      };
    };
  };

  config = lib.mkIf cfg.enable {

    services.nix-serve = {
      enable = true;
      port = cfg.port;
      secretKeyFile = cfg.secretKeyFile;
      package = pkgs.nix-serve-ng;
      # Set lower priority than official cache (cache.nixos.org is 40)
      # Higher number = lower priority, so clients prefer official cache first
      extraParams = "--priority 100";
    };

    services.cloudflared = {
      enable = true;
      tunnels = {
        "${cfg.cloudflare.tunnelId}" = {
          credentialsFile = cfg.cloudflare.credentialsFile;
          default = "http_status:404";
          ingress = {
            "${cfg.cloudflare.domain}" = "http://127.0.0.1:${toString cfg.port}";
          };
        };
      };
    };
  };
}
