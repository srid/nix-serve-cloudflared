{
  description = "Example usage of nix-serve-cloudflared module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-serve-cloudflared.url = "github:srid/nix-serve-cloudflared/init";
    agenix.url = "github:ryantm/agenix";
  };

  outputs = { self, nixpkgs, nix-serve-cloudflared, agenix, ... }: {
    nixosConfigurations.example = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        agenix.nixosModules.default
        nix-serve-cloudflared.nixosModules.default
        ({ pkgs, ... }: {
          # Minimal system configuration for the example
          boot.loader.grub.device = "nodev";
          fileSystems."/" = {
            device = "none";
            fsType = "tmpfs";
          };

          # Enable the nix-serve-cloudflared service
          services.nix-serve-cloudflared = {
            enable = true;
            port = 5000;
            secretKeyPath = "nix-serve-cloudflared/cache-key.pem";
            cloudflare = {
              tunnelId = "your-tunnel-id-here";
              credentialsPath = "nix-serve-cloudflared/cloudflared-credentials.json";
              domain = "cache.example.com";
            };
          };

          # Required for agenix
          age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

          system.stateVersion = "24.05";
        })
      ];
    };
  };
}
