let
  nixpkgs = fetchTarball {
    url = "https://releases.nixos.org/nixpkgs/nixpkgs-20.09pre213040.f77e057cda6/nixexprs.tar.xz";
    sha256 = "1khcsagyah8j7kmmmysvm1bprszp7ivvp0q0jvgy3kgcnxfs3pr9";
  };

in (import nixpkgs {}).callPackage (
  { stdenvNoCC, fetchgit, lib
  , texlive, pdftk }:

  stdenvNoCC.mkDerivation {
    name = "os-lectures-0";

    src = fetchgit {
      inherit (builtins.fromJSON (lib.readFile ./repo.json))
        url rev sha256 fetchSubmodules;
    };

    nativeBuildInputs = [ texlive.combined.scheme-full pdftk ];

    buildPhase = ''
      shopt -s nullglob
      mkdir -p "$out/logs"
      for lec in lecture*; do
        mkdir -p $out/logs/lec
        make -f "${./Makefile}" -C "$lec"
        cp "$lec/"*.pdf "$out"
        cp "$lec/"*.log "$out/logs/$lec"
      done
    '';
  }) {}
