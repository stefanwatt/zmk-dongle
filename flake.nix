{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    zmk-nix = {
      url = "github:lilyinstarlight/zmk-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, zmk-nix }: let
    forAllSystems = nixpkgs.lib.genAttrs (nixpkgs.lib.attrNames zmk-nix.packages);
  in {
    packages = forAllSystems (system: let
      zmk = zmk-nix.legacyPackages.${system};

      src = nixpkgs.lib.sourceFilesBySuffices self [
        ".board" ".cmake" ".conf" ".defconfig" ".dts" ".dtsi"
        ".json" ".keymap" ".overlay" ".shield" ".yml" "_defconfig"
      ];

      board = "nice_nano//zmk";

      zephyrDepsHash = "sha256-YOJgR564YhmmERIQA/dStKzScvlGOnmooSe7G1HSxZM=";
    in rec {
      default = skeletyl;

      skeletyl = zmk.buildSplitKeyboard {
        name = "skeletyl";
        inherit src board zephyrDepsHash;
        shield = "skeletyl_%PART%";
        parts = [ "dongle" "left" "right" ];
        centralPart = "dongle";
        meta = {
          description = "Skeletyl ZMK firmware (dongle + left + right)";
          license = nixpkgs.lib.licenses.mit;
          platforms = nixpkgs.lib.platforms.all;
        };
      };

      cygnus = zmk.buildSplitKeyboard {
        name = "cygnus";
        inherit src board zephyrDepsHash;
        shield = "cygnus_%PART%";
        parts = [ "left" "right" ];
        meta = {
          description = "Cygnus ZMK firmware (left + right)";
          license = nixpkgs.lib.licenses.mit;
          platforms = nixpkgs.lib.platforms.all;
        };
      };

      settings_reset = zmk.buildKeyboard {
        name = "settings_reset";
        inherit src board zephyrDepsHash;
        shield = "settings_reset";
        meta = {
          description = "ZMK settings reset firmware";
          license = nixpkgs.lib.licenses.mit;
          platforms = nixpkgs.lib.platforms.all;
        };
      };

      flash = zmk-nix.packages.${system}.flash.override { firmware = skeletyl; };
      update = zmk-nix.packages.${system}.update;
    });

    devShells = forAllSystems (system: {
      default = zmk-nix.devShells.${system}.default;
    });
  };
}
