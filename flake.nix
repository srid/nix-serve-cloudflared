{
  description = "NixOS module for nix-serve-ng with Cloudflare tunnel";

  inputs = { };

  outputs = { self }: {
    nixosModules.default = import ./default.nix;
  };
}
