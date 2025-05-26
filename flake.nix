{
  description = "An honest Finger protocol server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    systems.url = "github:nix-systems/default";

    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
  };

  outputs =
    {
      flake-utils,
      nixpkgs,
      self,
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
          pkgs.buildGo123Module.override { stdenv = pkgs.stdenvAdapters.useMoldLinker pkgs.clangStdenv; }
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
          inherit gigi;

          default = self.packages.${system}.gigi;
        };

        apps = {
          gigi = {
            inherit meta;

            type = "app";
            program = "${self.packages.${system}.default}/bin/gigi";
          };

          default = self.apps.${system}.gigi;
        };

        devShells.default = pkgs.mkShell { buildInputs = [ pkgs.go_1_23 ]; };
      }
    );
}
