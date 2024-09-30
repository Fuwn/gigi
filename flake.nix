{
  description = "An honest Finger protocol server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    systems.url = "github:nix-systems/default";

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };

    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";

      inputs = {
        flake-compat.follows = "flake-compat";
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      pre-commit-hooks,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        meta = with pkgs.lib; {
          description = "An honest Finger protocol server";
          homepage = "https://github.com/Fuwn/gigi";
          license = [
            licenses.mit
            licenses.asl20
          ];
          maintainers = [ maintainers.Fuwn ];
          mainPackage = "gigi";
          platforms = platforms.linux;
        };

        gigi =
          pkgs.buildGo122Module.override { stdenv = pkgs.stdenvAdapters.useMoldLinker pkgs.clangStdenv; }
            {
              inherit meta;

              pname = "gigi";
              version = "0.2.0";
              src = pkgs.lib.cleanSource ./.;
              vendorHash = null;
              buildInputs = [ pkgs.musl ];

              ldflags = [
                "-s"
                "-w"
                "-linkmode=external"
                "-extldflags=-static"
              ];
            };
      in
      {
        packages = {
          default = gigi;
          gigi = self.packages.${system}.default;
        };

        apps = {
          default = {
            inherit meta;

            type = "app";
            program = "${self.packages.${system}.default}/bin/gigi";
          };

          gigi = self.apps.${system}.default;
        };

        formatter = nixpkgs.legacyPackages."${system}".nixfmt-rfc-style;

        checks.pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;

          hooks = {
            deadnix.enable = true;
            flake-checker.enable = true;
            nixfmt-rfc-style.enable = true;
            statix.enable = true;
          };
        };

        devShells.default = nixpkgs.legacyPackages.${system}.mkShell {
          inherit (self.checks.${system}.pre-commit-check) shellHook;

          buildInputs = self.checks.${system}.pre-commit-check.enabledPackages ++ [
            pkgs.go_1_22
          ];
        };
      }
    );
}
