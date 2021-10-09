{ pkgs }:

let
  script = ''
    set -xe

    export PATH="${pkgs.coreutils}/bin:${pkgs.nixUnstable}/bin:$PATH"

    nix \
      --extra-system-features recursive-nix \
      --experimental-features "nix-command flakes ca-references ca-derivations recursive-nix" \
      build -f "$path" -o result

    ln -s "$(readlink ./result)" "$out"
  '';
in
name: path: builtins.derivation {
  inherit (pkgs) system;
  inherit name path;
  builder = "${pkgs.bash}/bin/sh";
  requiredSystemFeatures = [ "recursive-nix" ];
  args = [ "-c" script ];
}
