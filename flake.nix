{
  description = "BrowserOS packaged for Nix, with fully automated upstream updates";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgsFor = system: import nixpkgs { inherit system; };
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
          browseros = pkgs.callPackage ./package.nix { };
        in
        {
          inherit browseros;
          default = browseros;
        }
      );

      apps = forAllSystems (system: {
        browseros = {
          type = "app";
          program = "${self.packages.${system}.browseros}/bin/browseros";
          meta.description = "BrowserOS";
        };
        default = {
          type = "app";
          program = "${self.packages.${system}.browseros}/bin/browseros";
          meta.description = "BrowserOS";
        };
      });

      overlays.default = final: _prev: {
        browseros = final.callPackage ./package.nix { };
      };

      checks = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
          browseros = self.packages.${system}.browseros;
        in
        {
          inherit browseros;

          package-layout =
            pkgs.runCommand "browseros-package-layout"
              {
                nativeBuildInputs = [ pkgs.desktop-file-utils ];
              }
              ''
                test -x ${browseros}/bin/browseros
                test -f ${browseros}/share/applications/browseros.desktop
                desktop-file-validate ${browseros}/share/applications/browseros.desktop
                touch "$out"
              '';

          shellcheck =
            pkgs.runCommand "browseros-shellcheck"
              {
                nativeBuildInputs = [ pkgs.shellcheck ];
              }
              ''
                shellcheck ${./scripts/update-browseros}
                shellcheck ${./scripts/check-source}
                shellcheck ${./scripts/validate-local}
                touch "$out"
              '';

          actionlint =
            pkgs.runCommand "browseros-actionlint"
              {
                nativeBuildInputs = [ pkgs.actionlint ];
              }
              ''
                actionlint \
                  ${./.github/workflows/ci.yml} \
                  ${./.github/workflows/update-browseros.yml} \
                  ${./.github/workflows/maintenance.yml}
                touch "$out"
              '';
        }
      );

      formatter = forAllSystems (system: (pkgsFor system).nixfmt);

      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              actionlint
              curl
              desktop-file-utils
              git
              jq
              nixfmt
              python3
              shellcheck
            ];
          };
        }
      );
    };
}
