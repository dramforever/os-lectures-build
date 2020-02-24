let
  nixpkgs = fetchTarball {
    url = "https://releases.nixos.org/nixpkgs/nixpkgs-20.09pre213040.f77e057cda6/nixexprs.tar.xz";
    sha256 = "1khcsagyah8j7kmmmysvm1bprszp7ivvp0q0jvgy3kgcnxfs3pr9";
  };

in (import nixpkgs {}).callPackage (
  { stdenvNoCC, fetchgit, lib, makeFontsConf
  , noto-fonts, noto-fonts-extra
  , texlive, fontconfig, pdftk }:

  let noto-fonts-cjk-ttc = stdenvNoCC.mkDerivation {
    name = "noto-fonts-cjk-ttc-2.001";
    src = fetchgit {
      url = "https://github.com/googlefonts/noto-cjk.git";
      rev = "be6c059ac1587e556e2412b27f5155c8eb3ddbe6";
      sha256 = "0p6mhpg89f9zc4vpi42pn2jm900hs44ns0p2kh6jcs1a2p9ma69w";
    };

    phases = [ "unpackPhase" "installPhase" ];

    installPhase = ''
      mkdir -p "$out/share/fonts/noto-cjk"
      cp *.ttc "$out/share/fonts/noto-cjk"
    '';
  };

  in stdenvNoCC.mkDerivation {
    name = "os-lectures-0";

    src = fetchgit {
      inherit (builtins.fromJSON (lib.readFile ./repo.json))
        url rev sha256 fetchSubmodules;
    };

    nativeBuildInputs = [
      texlive.combined.scheme-full
      fontconfig
      pdftk
    ];

    FONTCONFIG_FILE = makeFontsConf {
      fontDirectories = [
        noto-fonts
        noto-fonts-cjk-ttc
        noto-fonts-extra
      ];
    };

    phases = [ "unpackPhase" "patchPhase" "buildPhase" ];

    patches = [ ./handout-mode.patch ];

    buildPhase = ''
      shopt -s nullglob
      mkdir -p "$out/all_pdfs" "$out/logs"

      touch "$out/failed"

      for lec in lecture*; do
        if make -k -f "${./Makefile}" -C "$lec"; then
          cp "$lec/$lec".pdf "$out"
        else
          echo "- $lec" >> "$out/failed"
        fi

        cp "$lec/"*.pdf "$out/all_pdfs"
        cp "$lec/"*.log "$out/logs"
      done
    '';
  }) {}
