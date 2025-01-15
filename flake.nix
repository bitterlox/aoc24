{
  description = "Advent of code 2024 in zig";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };
  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      perSystem =
        { pkgs, lib, ... }:
        {
          devShells.default = pkgs.mkShell {
            name = "koreader devenv";
            packages = with pkgs; [ zig ];
            shellHook = ''
              echo "welcome to a zig devshell"
            '';
          };
        };
    };
}
