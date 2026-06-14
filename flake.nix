{
  description = ''
    Uses flake-parts to set up the flake outputs:

    `wrappers`, `wrapperModules` and `packages.*.*`
  '';
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    };
    wrappers = {
      url = "github:BirdeeHub/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    wezterm = {
      url = "github:wezterm/wezterm?dir=nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      wrappers,
      flake-parts,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ wrappers.flakeModules.wrappers ];
      systems = nixpkgs.lib.platforms.all;

      perSystem =
        { pkgs, ... }:
        {
          # wrappers.pkgs = pkgs; # choose a different `pkgs`
          wrappers.control_type = "exclude"; # | "build"  (default: "exclude")
          wrappers.packages = {
            hello = false; # <- set to true to exclude from being built into `packages.*.*` flake output
          };
        };
      flake.wrappers.hello = ./hello.nix;
      flake.wrappers.wezterm = {
        imports = [ (flake-parts.lib.importApply ./wezterm/wezterm.nix { inherit inputs; }) ];
        colorScheme = "Tokyo Night";
        saveStateDir = "/home/pouya/.local/state/wezterm/sessions";
        fontSize = 10;
      };
    };
}
