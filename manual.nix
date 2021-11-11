{ pkgs }:

let
  drv = pkgs.runCommand "hello-${pkgs.hello.version}.drv" {
    __contentAddressed = true;
    outputHashAlgo = "sha256";
    outputHashMode = "text";
  } ''
    cat > $out <<END
    Derive([("out","${builtins.unsafeDiscardStringContext pkgs.hello.outPath}","","")],[("${pkgs.hello.src.drvPath}",["out"]),("${pkgs.stdenv.drvPath}",["out"]),("${pkgs.bash.drvPath}",["out"])],["${builtins.elemAt pkgs.hello.args 1}"],"x86_64-linux","${pkgs.bash}/bin/bash",["-e","${builtins.elemAt pkgs.hello.args 1}"],[("buildInputs",""),("builder","${pkgs.bash}/bin/bash"),("configureFlags",""),("depsBuildBuild",""),("depsBuildBuildPropagated",""),("depsBuildTarget",""),("depsBuildTargetPropagated",""),("depsHostHost",""),("depsHostHostPropagated",""),("depsTargetTarget",""),("depsTargetTargetPropagated",""),("doCheck","1"),("doInstallCheck",""),("name","hello-2.10"),("nativeBuildInputs",""),("out","${builtins.unsafeDiscardStringContext pkgs.hello.outPath}"),("outputs","out"),("patches",""),("pname","${pkgs.hello.pname}"),("propagatedBuildInputs",""),("propagatedNativeBuildInputs",""),("src","${pkgs.hello.src}"),("stdenv","${pkgs.stdenv}"),("strictDeps",""),("system","x86_64-linux"),("version","${pkgs.hello.version}")])
    END
  '';
in
# This doesn't actually work with `nix build`
/*
rec {
  type = "derivation";
  drvPath = drv.outPath;
  outPath = builtins.outputOf drvPath "out";
}
*/
pkgs.runCommand "hello-wrapper" {} ''
  ln -s ${builtins.outputOf drv.outPath "out"} $out
''
