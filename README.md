# browseros-nix

A small, reproducible Nix package for [BrowserOS](https://github.com/browseros-ai/BrowserOS) that updates itself when BrowserOS publishes a new stable Linux x64 AppImage.

The repository is designed so that the maintainer does **not** manually edit BrowserOS versions or hashes after the initial publish.

## How updates work

BrowserOS shares one GitHub Releases feed with server and extension releases, so the updater deliberately does **not** use `/releases/latest`. It scans stable releases for a plain `vX.Y.Z`-style browser tag and requires an asset named exactly:

```text
BrowserOS_<tag>_x64.AppImage
```

The updater writes only `source.nix`. It uses the SHA-256 digest exposed by the GitHub release asset when available, otherwise it asks Nix to prefetch the file and calculate the SHA-256 itself. The resulting package is still a normal fixed-output, reproducible Nix derivation.

`.github/workflows/update-browseros.yml` checks upstream four times per day. When a new BrowserOS release appears it:

1. regenerates `source.nix`;
2. runs formatting checks;
3. runs `nix flake check` (including ShellCheck, actionlint, package build, and desktop-entry validation);
4. builds BrowserOS explicitly; and
5. commits the update only after all checks pass.

`.github/workflows/maintenance.yml` refreshes the pinned `nixpkgs` input monthly and records a maintenance heartbeat after successful checks. The heartbeat is intentional: GitHub can disable scheduled workflows in a public repository after 60 days without repository activity.

## First-time bootstrap

The distributed archive intentionally contains a fake hash in `source.nix`, so there is no stale binary hash pretending to be validated. Before the initial push, run:

```bash
./scripts/validate-local
```

That command resolves the current release, writes the real hash, creates/updates `flake.lock`, formats/checks the repository, builds BrowserOS, and verifies that a second updater run is idempotent.

For an additional executable smoke test:

```bash
BROWSEROS_RUN_SMOKE_TEST=1 ./scripts/validate-local
```

## Usage

Run directly from a published repository:

```bash
nix run github:<owner>/browseros-nix
```

Build it:

```bash
nix build github:<owner>/browseros-nix#browseros
```

Install it into a profile:

```bash
nix profile install github:<owner>/browseros-nix#browseros
```

Use as a flake input:

```nix
{
  inputs.browseros-nix.url = "github:<owner>/browseros-nix";

  outputs = { nixpkgs, browseros-nix, ... }: {
    nixosConfigurations.my-host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ pkgs, ... }: {
          environment.systemPackages = [
            browseros-nix.packages.${pkgs.system}.browseros
          ];
        })
      ];
    };
  };
}
```

A consuming flake's own `flake.lock` will intentionally pin this repository. Updating that consumer lock is separate from this repository automatically tracking BrowserOS upstream.

## Supported platform

Currently:

- `x86_64-linux`

Support can be extended to ARM64 once the GitHub release channel consistently exposes and validates a Linux ARM64 AppImage under a stable naming contract.

## Security properties

- BrowserOS runs from an immutable `/nix/store` package, not from a runtime downloader.
- Upstream assets are fixed by SHA-256.
- The updater rejects drafts and prereleases.
- The updater rejects server/extension release tags and requires the exact browser AppImage filename.
- A changed source is committed only after the Nix checks and build pass.
- GitHub Actions receives only the permissions it needs (`contents: read` for CI, `contents: write` for automated update commits).

For maximum GitHub Actions supply-chain hardening, replace the versioned action references with immutable full commit SHAs during the initial local review. The validation prompt supplied with the archive explicitly asks the reviewer to do this before publishing.

## License

The packaging code in this repository is MIT licensed. BrowserOS itself is distributed under its upstream license (AGPL-3.0-only at the time this repository was created).
