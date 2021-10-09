{
  description = "nix build inside nix build using RFC 92";

  inputs.nix.url = "github:obsidiansystems/nix?ref=refs/heads/dynamic-drvs";

  outputs = { self, nix }:
  let
    nixpkgs = nix.inputs.nixpkgs;

    supportedSystems = [ "x86_64-linux" "aarch64-linux" ];

    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
  in
  {
    nixBuild = system: import ./nix-build.nix {
      pkgs = import nixpkgs { inherit system; };
      inherit (self.packages.${system}) nix92;
    };
    nixBuildRec = system: import ./nix-build-recursive.nix {
      pkgs = import nixpkgs { inherit system; };
    };
    nixBuildIFD = _system: _name: path: (import path).out;


    packages = forAllSystems (system:
      let
        pkgs = import nixpkgs { inherit system; };
        hello-nix = pkgs.writeText "hello.nix" ''
          with import (${nixpkgs}) {}; hello
        '';
      in
      {
        hello = self.nixBuild system "hello-rfc92" hello-nix;
        helloRec = self.nixBuildRec system "hello-rec" hello-nix;
        helloIFD = self.nixBuildIFD system "hello-ifd" hello-nix;
        nix92 = nix.packages.${system}.nix.overrideAttrs (_: {
          doCheck = false;
          doInstallCheck = false;
        });
      }
    );

    checks = forAllSystems (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        helloRec = pkgs.runCommand "hello-rec-check" {
          nativeBuildInputs = [ self.packages.${system}.nix92 pkgs.curl ];
          outputHash = "Db2F9nSNXWKOGZKs8HLqZEAKLDtMK3IW5CxNffiKcG0=";
          outputHashMode = "recursive";
          outputHashAlgo = "sha256";
          SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
          NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        } ''
          mkdir myhome
          export HOME="$(realpath ./myhome)"
          mkdir mystore
          nix \
            --store "$(realpath ./mystore)" \
            --extra-system-features recursive-nix \
            --experimental-features "nix-command flakes recursive-nix ca-references ca-derivations" \
            build path:${self}#helloRec --print-build-logs --log-format bar-with-logs
          readlink ./result | tail -c +10 > $out
        '';
        hello = pkgs.runCommand "hello-check" {
          nativeBuildInputs = [ self.packages.${system}.nix92 pkgs.curl ];
          outputHash = "mO/xrv5A0jYB9uJawkTXpNZIrgyAtqG+pUCkv0wnhkA=";
          outputHashMode = "recursive";
          outputHashAlgo = "sha256";
          SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
          NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        } ''
          mkdir myhome
          export HOME="$(realpath ./myhome)"
          mkdir mystore
          nix \
            --store "$(realpath ./mystore)" \
            --extra-system-features recursive-nix \
            --experimental-features "nix-command flakes recursive-nix ca-references ca-derivations" \
            build path:${self}#hello --print-build-logs --log-format bar-with-logs
          readlink ./result | tail -c +10 > $out
        '';
        # FIXME: fails
        /*
        helloIFD = pkgs.runCommand "hello-ifd-check" {
          nativeBuildInputs = [ pkgs.nixUnstable pkgs.curl ];
          outputHash = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
          outputHashMode = "recursive";
          outputHashAlgo = "sha256";
          SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
          NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        } ''
          mkdir myhome
          export HOME="$(realpath ./myhome)"
          mkdir mystore
          nix \
            --store "$(realpath ./mystore)" \
            --extra-system-features recursive-nix \
            --experimental-features "nix-command flakes recursive-nix ca-references ca-derivations" \
            build path:${self}#helloIFD --impure --print-build-logs --log-format bar-with-logs
          readlink ./result | tail -c +10 > $out
        '';
        */
      }
    );
  };
 
}
