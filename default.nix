{ nixpkgs ? <nixpkgs>
, config ? {}
}:

with (import nixpkgs config);

let
  mkDerivation =
    { srcs ? ./elm-srcs.nix
    , src
    , name
    , srcdir ? "./src"
    , targets ? []
    , versionsDat ? ./versions.dat
    }:
    stdenv.mkDerivation {
      inherit name src;

      buildInputs = [
        elmPackages.elm
        nodePackages.uglify-js
      ];

      buildPhase = pkgs.elmPackages.fetchElmDeps {
        elmPackages = import srcs;
        inherit versionsDat;
      };

      installPhase = let
        elmfile = module: "${srcdir}/${builtins.replaceStrings ["."] ["/"] module}.elm";
      in ''
        ${lib.concatStrings (map (module: ''
          echo "compiling ${elmfile module}"
          elm make ${elmfile module} --optimize --output=$out/elm.js
          uglifyjs $out/elm.js --compress 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters,keep_fargs=false,unsafe_comps,unsafe' | uglifyjs --mangle --output=$out/elm.min.js
        '') targets)}
        cp index.html $out/index.html
      '';
    };
in mkDerivation {
  name = "elm-ui-todomvc-1.0.0";
  srcs = ./elm-srcs.nix;
  src = ./.;
  targets = ["Main"];
  srcdir = "./src";
}

