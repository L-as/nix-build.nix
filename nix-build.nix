{ pkgs, nix, ifd }:

let
  wrapNix = path: pkgs.writeText "wrapNix.nix" ''
    let
      drv = import ${path};
      wrapNixScript = '''
        "$coreutils/bin/ln" -s ''${drv.out} $out
      ''';
    in
    derivation {
      name = "nix-build";
      system = "x86_64-linux";
      builder = "/bin/sh";
      args = [ "-c" wrapNixScript ];
      coreutils = (import ${pkgs.path} {}).coreutils;
    }
  '';
  script = ''
    export PATH="${pkgs.coreutils}/bin:${nix}/bin:$PATH"
    cp "$(nix-instantiate "$input")" $out
  '';
  nixBuildUnwrapped =
    if ifd
    then path: (import (wrapNix path)).out
    else path:
      let
        drv = derivation {
          name = "nix-build.drv";
          inherit (pkgs) system;
          builder = "/bin/sh";
          requiredSystemFeatures = [ "recursive-nix" ];
          input = "${wrapNix path}";
          args = [ "-c" script ];
          __contentAddressed = true;
          outputHashMode = "text";
          outputHashAlgo = "sha256";
        };
      in
      builtins.outputOf drv.out "out";
  wrapper = path: pkgs.runCommand "nix-build-wrapper" {} ''
    ln -s ${path} $out
  '';
  nixBuild = path: wrapper (nixBuildUnwrapped path);
in
{
  inherit nixBuild;
}
