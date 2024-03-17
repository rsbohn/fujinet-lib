let
  pkgs = import <nixpkgs> {};
  ver = builtins.readFile ./version.txt;
in pkgs.stdenv.mkDerivation {
    pname = "fujinet-lib";
    version = ver;
    src = ./.;

    buildInputs = [
    	pkgs.cc65
    	pkgs.zip
    ];

    installPhase = ''
        mkdir -p $out
        mv dist $out/
    '';
}
