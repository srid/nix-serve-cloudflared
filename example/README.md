# Example Usage

This directory contains an example flake demonstrating how to use the `nix-serve-cloudflared` NixOS module.

## Setup

1. **Create a Cloudflare tunnel:**
   ```bash
   cloudflared tunnel create my-nix-cache
   ```
   Note the tunnel ID from the output.

2. **Generate a cache signing key:**
   ```bash
   nix-store --generate-binary-cache-key cache.example.com cache-key.pem cache-key.pub
   ```

3. **Encrypt secrets with agenix:**

   Create the secrets directory structure:
   ```bash
   mkdir -p secrets/nix-serve-cloudflared
   ```

   Encrypt the cache signing key:
   ```bash
   agenix -e secrets/nix-serve-cloudflared/cache-key.pem.age
   # Paste the contents of cache-key.pem
   ```

   Encrypt the Cloudflare credentials:
   ```bash
   agenix -e secrets/nix-serve-cloudflared/cloudflared-credentials.json.age
   # Paste the contents of ~/.cloudflared/<tunnel-id>.json
   ```

4. **Update the flake.nix:**

   Edit `flake.nix` and replace:
   - `your-tunnel-id-here` with your actual tunnel ID
   - `cache.example.com` with your actual domain

5. **Build the configuration:**
   ```bash
   nix build .#nixosConfigurations.example.config.system.build.toplevel
   ```

## Testing

To test this configuration in a VM or deploy it to a NixOS system, you can use:

```bash
nixos-rebuild build-vm --flake .#example
```

## Notes

- This example uses `path:..` as the input for `nix-serve-cloudflared` to reference the parent directory
- In production, you would use a GitHub URL or other remote source
- The secrets files referenced must exist in the parent directory (`../secrets/`)
- Make sure your Cloudflare tunnel DNS is properly configured to point to your domain
