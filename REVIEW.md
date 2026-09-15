# Pre-publication review checklist

The intended local reviewer should complete all of these before the first public push:

- Run `./scripts/update-browseros` and inspect the generated `source.nix`.
- Run `nix flake lock` and commit `flake.lock`.
- Pin every external GitHub Action in `.github/workflows/*.yml` to an immutable full commit SHA and retain a version comment.
- Run `./scripts/check-source`.
- Run `nix fmt -- --check flake.nix package.nix source.nix`.
- Run `nix flake check --print-build-logs`.
- Run `nix build .#browseros --print-build-logs`.
- Confirm `result/bin/browseros` exists and is executable.
- Confirm the desktop file passes `desktop-file-validate` (also covered by flake checks).
- Run `result/bin/browseros --version` if the local graphical/runtime environment permits it.
- Launch BrowserOS once on NixOS and confirm a window opens and basic browsing works.
- Re-run `./scripts/update-browseros` and verify it produces no diff.
- Review workflow permissions and scheduled-update behavior.
- Only then create/push the public GitHub repository.
