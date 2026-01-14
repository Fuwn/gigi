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
        inherit (pkgs.stdenv) isDarwin;

        pkgs = import nixpkgs { inherit system; };
        version = "0.2.2";

        meta = with pkgs.lib; {
          description = "An honest Finger protocol server";
          homepage = "https://github.com/Fuwn/gigi";
          license = [
            licenses.mit
            licenses.asl20
          ];
          maintainers = [ maintainers.Fuwn ];
          mainPackage = "gigi";
          platforms = platforms.unix;
        };

        gigi =
          pkgs.buildGo123Module.override
            {
              stdenv = if isDarwin then pkgs.clangStdenv else pkgs.stdenvAdapters.useMoldLinker pkgs.clangStdenv;
            }
            {
              inherit meta version;

              pname = "gigi";
              src = pkgs.lib.cleanSource ./.;
              vendorHash = null;
              buildInputs = if isDarwin then [ ] else [ pkgs.musl ];

              ldflags =
                [
                  "-s"
                  "-w"
                  "-X main.Version=${version}"
                  "-X main.Commit=${version}"
                ]
                ++ (
                  if isDarwin then
                    [ ]
                  else
                    [
                      "-linkmode=external"
                      "-extldflags=-static"
                    ]
                );
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
