{ pkgs, nix92 }:

let
  innerWrapper = name: path: pkgs.writeText (name + "-nix-build-wrapper.nix") ''
    let
      drv = import (builtins.storePath ${path});
      innerScript = '''
        "$coreutils/bin/ln" -s ''${drv.out} $out
      ''';
      bash = builtins.storePath ${pkgs.bash};
    in
    derivation {
      name = "${name}";
      system = "${pkgs.system}";
      builder = "''${bash}/bin/sh";
      args = [ "-c" innerScript ];
      coreutils = (import ${pkgs.path} {}).coreutils;
    }
  '';
  script = ''
    export PATH="${pkgs.coreutils}/bin:${nix92}/bin:$PATH"
    cp "$(nix-instantiate "$input" --no-allow-import-from-derivation)" $out
  '';
  nixBuildUnwrapped =
    name: path:
      let
        drv = builtins.derivation {
          name = name + ".drv";
          inherit (pkgs) system;
          builder = "${pkgs.bash}/bin/sh";
          requiredSystemFeatures = [ "recursive-nix" ];
          input = innerWrapper name path;
          args = [ "-c" script ];
          __contentAddressed = true;
          outputHashMode = "text";
          outputHashAlgo = "sha256";
        };
      in
      builtins.outputOf drv.out "out";
  wrapper = name: path: pkgs.runCommand (name + "-nix-build-wrapped") {} ''
    ln -s ${path} $out
  '';
in
name: path: wrapper name (nixBuildUnwrapped name path)
