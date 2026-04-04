{
  # Quick comment
  description = "OpenCode - A powerful terminal-based AI assistant for developers";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    opencode.url = "github:anomalyco/opencode/v1.3.14";
    opencode-tps-patch.url = "github:guard22/opencode-tps-meter/main";
    opencode-tps-patch.flake = false;
  };

  outputs =
    { self, nixpkgs, opencode, opencode-tps-patch, ... }:
    let
      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      forEachSystem =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          f {
            pkgs = nixpkgs.legacyPackages.${system};
            inherit system;
          }
        );
    in
    {
      packages = forEachSystem (
        { pkgs, system }:
        let
          tpsPatch = pkgs.fetchpatch {
            url = "https://raw.githubusercontent.com/guard22/opencode-tps-meter/main/patches/opencode-1.3.14-tps.patch";
            hash = "sha256-VYCIefxvDlG0WC1r6IReFVz7NDFSgNN0jMbJSxKMXZU=";
          };
        in
        {
          opencode = pkgs.callPackage ./package.nix { };
          opencode-webui-permission-patched =
            pkgs.opencode.overrideAttrs (oldAttrs: {
              postPatch = (oldAttrs.postPatch or "") + ''
                if [ -f packages/app/src/pages/session.tsx ]; then
                  substituteInPlace packages/app/src/pages/session.tsx \
                    --replace "if (next.tool) return;" ""
                fi
              '';
            });
          opencode-tps-meter =
            let
              upstream = opencode.packages.${system}.opencode;
            in
            upstream.overrideAttrs (oldAttrs: {
              pname = "opencode-tps-meter";
              patches = (oldAttrs.patches or [ ]) ++ [ tpsPatch ];
              postPatch =
                (oldAttrs.postPatch or "")
                + ''
                  substituteInPlace packages/opencode/src/installation/meta.ts \
                    --replace-fail '"1.3.14"' '"${oldAttrs.version or "1.3.14"}"' \
                    --replace-fail '"latest"' '"local"'
                '';
            });
          openspec = pkgs.callPackage ./openspec.nix { };
          opencode-nvim = pkgs.callPackage ./opencode-nvim.nix { };
          opencode-google-antigravity-auth = pkgs.callPackage ./opencode-google-antigravity-auth.nix { };
          default = self.packages.${system}.opencode;
        }
      );

      apps = forEachSystem (
        { pkgs, system }:
        {
          opencode = {
            type = "app";
            program = "${self.packages.${system}.opencode}/bin/opencode";
          };
          opencode-webui-permission-patched = {
            type = "app";
            program = "${self.packages.${system}.opencode-webui-permission-patched}/bin/opencode";
          };
          opencode-tps-meter = {
            type = "app";
            program = "${self.packages.${system}.opencode-tps-meter}/bin/opencode";
          };
          default = self.apps.${system}.opencode;
        }
      );

       devShells = forEachSystem (
         { pkgs, system }:
         {
           default = pkgs.mkShell {
             buildInputs = with pkgs; [
                self.packages.${system}.opencode
                self.packages.${system}.openspec
                self.packages.${system}.opencode-nvim
                self.packages.${system}.opencode-google-antigravity-auth
                self.packages.${system}.opencode-tps-meter
             ];
           };
         }
       );

         checks = forEachSystem (
           { pkgs, system }:
           {
             opencode = self.packages.${system}.opencode;
             openspec = self.packages.${system}.openspec;
             opencode-nvim = self.packages.${system}.opencode-nvim;
             opencode-google-antigravity-auth = self.packages.${system}.opencode-google-antigravity-auth;
           }
         );
    };
}
