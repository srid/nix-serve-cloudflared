# nix-serve-cloudflared

NixOS module that sets up a Nix binary cache server using `nix-serve-ng` and exposes it through a Cloudflare tunnel.

## Features

- Runs `nix-serve-ng` to serve Nix store paths over HTTP
- Automatically configures Cloudflare tunnel for secure external access
- Signs cache content with a private key for verification
- Integrated with [agenix](https://github.com/ryantm/agenix) for secure secret management

## Prerequisites

- [agenix](https://github.com/ryantm/agenix) configured in your NixOS setup
- A Cloudflare account with a domain

## Getting Started

### 1. Add as a flake input

Add to your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-serve-cloudflared.url = "github:srid/nix-serve-cloudflared";
    # ... other inputs
  };

  outputs = { self, nixpkgs, nix-serve-cloudflared, ... }: {
    nixosConfigurations.your-host = nixpkgs.lib.nixosSystem {
      modules = [
        nix-serve-cloudflared.nixosModules.default
        # ... your other modules
      ];
    };
  };
}
```

### 2. Setup secrets and Cloudflare tunnel

1. **Generate cache signing key**:
   ```bash
   nix-store --generate-binary-cache-key cache.example.com cache-priv-key.pem cache-pub-key.pem
   ```
   Keep `cache-pub-key.pem` for clients. The private key will be encrypted with agenix.

2. **Authenticate with Cloudflare** (first time only):
   ```bash
   nix run nixpkgs#cloudflared -- tunnel login
   ```
   This opens a browser to authenticate and downloads a certificate to `~/.cloudflared/cert.pem`.

3. **Create Cloudflare tunnel**:
   ```bash
   nix run nixpkgs#cloudflared -- tunnel create nix-cache
   ```
   This creates a tunnel and generates credentials in `~/.cloudflared/`.
   Note the tunnel ID from the output.

4. **Update your `secrets/secrets.nix`** (before encrypting):
   ```nix
   {
     # ... other secrets
     "nix-serve-cloudflared/cache-key.pem.age".publicKeys = [ ... ];
     "nix-serve-cloudflared/cloudflared-credentials.json.age".publicKeys = [ ... ];
   }
   ```

5. **Encrypt secrets with agenix**:
   ```bash
   # Encrypt the cache signing key
   agenix -e secrets/nix-serve-cloudflared/cache-key.pem.age
   # Paste the contents of cache-priv-key.pem, save and exit
   
   # Encrypt the Cloudflare credentials
   agenix -e secrets/nix-serve-cloudflared/cloudflared-credentials.json.age
   # Paste the contents of ~/.cloudflared/<tunnel-id>.json, save and exit
   ```

6. **Add DNS record** in Cloudflare dashboard:
   - Type: CNAME
   - Name: your subdomain (e.g., `cache`)
   - Target: `<tunnel-id>.cfargotunnel.com`

### 3. Configure the service

In your NixOS configuration:

```nix
{ config, ... }: {
  # Set up agenix secrets
  age.secrets."nix-serve-cloudflared/cache-key.pem" = {
    file = ./secrets/nix-serve-cloudflared/cache-key.pem.age;
    mode = "0400";
  };

  age.secrets."nix-serve-cloudflared/cloudflared-credentials.json" = {
    file = ./secrets/nix-serve-cloudflared/cloudflared-credentials.json.age;
    mode = "0400";
  };

  # Configure the service
  services.nix-serve-cloudflared = {
    enable = true;
    port = 5000;  # Local port (default: 5000)
    secretKeyFile = config.age.secrets."nix-serve-cloudflared/cache-key.pem".path;

    cloudflare = {
      tunnelId = "your-tunnel-id-from-step-2.3";
      credentialsFile = config.age.secrets."nix-serve-cloudflared/cloudflared-credentials.json".path;
      domain = "cache.example.com";
    };
  };
}
```

### 4. Test the cache

```bash
# Test that nix-serve-ng is responding
curl https://cache.example.com/nix-cache-info
```

You should see output like:
```
StoreDir: /nix/store
WantMassQuery: 1
Priority: 30
```

## Using the Cache

On client machines, add to `/etc/nixos/configuration.nix`:

```nix
nix.settings = {
  substituters = [ "https://cache.example.com" ];
  trusted-public-keys = [ "cache.example.com:base64-encoded-public-key" ];
};
```

The public key content is in `cache-pub-key.pem` generated in setup step 2.1.

## Options

- **`enable`**: Enable the nix-serve-ng with Cloudflare tunnel service
- **`port`**: Local port for nix-serve-ng (default: 5000)
- **`secretKeyFile`**: Path to the cache signing key file (e.g., from agenix)
- **`cloudflare.tunnelId`**: Your Cloudflare tunnel ID
- **`cloudflare.credentialsFile`**: Path to the Cloudflare tunnel credentials file (e.g., from agenix)
- **`cloudflare.domain`**: Public domain name for the cache

## License

AGPL-3.0
