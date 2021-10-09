{
  description = "nix build inside nix build using RFC 92";

  inputs.nix.url = "github:obsidiansystems/nix?ref=refs/heads/dynamic-drvs";

  outputs = { self, nix }:
  let
    nixpkgs = nix.inputs.nixpkgs;

    supportedSystems = [ "x86_64-linux" "aarch64-linux" ];

    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

    ourNix = system: nix.packages.${system}.nix.overrideAttrs (_: {
      doCheck = false;
      doInstallCheck = false;
    });
  in
  {
    nixBuild' = ifd: system: path:
      let
        pkgs = import nixpkgs { inherit system; };
        nix = ourNix system;
      in
      (import ./nix-build.nix { inherit pkgs nix ifd; }).nixBuild path;
    nixBuild = self.nixBuild' false;
    nixBuildIFD = self.nixBuild' true;

    packages = forAllSystems (system:
      let
        pkgs = import nixpkgs { inherit system; };
        nix = ourNix system;
      in
      rec {
        hello-nix = pkgs.writeText "hello.nix" ''
          with import (${nixpkgs}) {}; hello
        '';
        hello = self.nixBuild system "${hello-nix}";
        helloIFD = self.nixBuildIFD system "${hello-nix}";
      }
    );

    /* FIXME: doesn't work
    checks = forAllSystems (system:
      let
        pkgs = import nixpkgs { inherit system; };
        nix = ourNix system;
      in
      {
        hello = pkgs.runCommand "hello-rfc92" {
          nativeBuildInputs = [ nix pkgs.curl ];
          outputHash = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
          outputHashMode = "recursive";
          outputHashAlgo = "sha256";
          SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
          NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        } ''
          mkdir myhome
          export HOME="$(realpath ./myhome)"
          mkdir mystore
          nix --store "$(realpath ./mystore)" --extra-system-features recursive-nix --experimental-features "nix-command flakes recursive-nix ca-references ca-derivations" build path:${self}#hello -L --log-format bar-with-logs
          mkdir $out
        '';
      }
    );
    */
  };
 
}
