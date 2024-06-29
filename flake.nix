{
  description = "A node.js (pnpm) dev environment";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
        };

        vtsls = pkgs.stdenv.mkDerivation rec {
          pname = "vtsls";
          version = "0.2.4";

          src = pkgs.fetchFromGitHub {
            owner = "yioneko";
            repo = "vtsls";
            rev = "server-v${version}";
            hash = "sha256-YJbvkC9ZY35thlp4cPWbQTdckcXU+I7IiSZ/xnr1WkA=";
            fetchSubmodules = true;
            leaveDotGit = true;
          };

          nativeBuildInputs = with pkgs; [
            git
            nodejs
            pnpm.configHook
          ];

          pnpmDeps = pkgs.pnpm.fetchDeps {
            inherit pname version src;
            hash = "sha256-PeJiUxMTfgXL0UVevfou61o8Y3rY1PtcI/W1qYX5WGU=";
          };

          buildPhase = ''
            runHook preBuild
            # Bypass submodule check WTF
            git add .
            pnpm -r build
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            mkdir -p $out/bin
            mkdir -p $out/lib/node_modules/@vtsls
            cp -r -L packages/server $out/lib/node_modules/@vtsls/language-server
            cp -r -L node_modules/.pnpm/lru-cache@6.0.0/node_modules/lru-cache $out/lib/node_modules/
            cp -r -L node_modules/.pnpm/yallist@4.0.0/node_modules/yallist $out/lib/node_modules/
            cp -r -L node_modules/.pnpm/vscode-jsonrpc@8.2.0/node_modules/vscode-jsonrpc $out/lib/node_modules/
            cp -r -L node_modules/.pnpm/vscode-languageserver-types@3.17.5/node_modules/vscode-languageserver-types $out/lib/node_modules/
            cp -r -L node_modules/.pnpm/vscode-languageserver-protocol@3.17.5/node_modules/vscode-languageserver-protocol $out/lib/node_modules/
            ln -s $out/lib/node_modules/@vtsls/language-server/bin/vtsls.js $out/bin/vtsls
            runHook postInstall
          '';
        };
      in {
        devShell = pkgs.mkShell {
          packages = [
            pkgs.nodejs
            pkgs.pnpm

            pkgs.nodePackages."@astrojs/language-server"
            pkgs.nodePackages.prettier

            vtsls
            pkgs.tailwindcss-language-server
          ];
        };
      }
    );
}
