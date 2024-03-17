let
  pkgs = import <nixpkgs> {};
  ver = "2.2.2";
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
