{
  # Quick comment
  description = "OpenCode - A powerful terminal-based AI assistant for developers";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs }:
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
