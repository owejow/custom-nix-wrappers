{ inputs }:
{
  wlib,
  pkgs,
  lib,
  config,
  ...
}:
let
  makeFontEnv =
    {
      fonts,
      includeSystem ? true,
    }:
    {
      data = "${pkgs.makeFontsConf {
        fontDirectories = fonts;

        # If includeSystem is true, pass the system file; otherwise, pass an empty list
        includes = if includeSystem then [ "/etc/fonts/fonts.conf" ] else [ ];
      }}";
    };
in
{
  imports = [ wlib.wrapperModules.wezterm ];
  options = {
    colorScheme = lib.mkOption {
      type = lib.types.str;
      default = "Tokyo Night Dark"; # Fallback theme if not overridden
      description = "The active color scheme for Wezterm.";
    };
    defaultProgram = lib.mkOption {
      type = lib.types.package;
      default = pkgs.bash;
      description = "The default shell or application to spawn inside the wrapped program.";
    };
    fonts = lib.mkOption {
      description = "An ordered list of valid font configuration objects.";
      default = [
        {
          family = "FiraCode Nerd Font Mono";
          scale = 1.20;
          weight = "Medium";
        }
        {
          family = "Noto Sans Mono CJK HK";
          scale = 1.50;
          weight = "Medium";
        }
        {
          family = "Jigmo";
          weight = "Medium";
          scale = 1.50;
        }
        {
          family = "Jigmo2";
          weight = "Medium";
          scale = 1.50;
        }
        {
          family = "Jigmo3";
          weight = "Medium";
          scale = 1.50;
        }
        {
          family = "Doulos SIL";
          scale = 1.50;
          weight = "Regular";
        }
      ];

      # Use lib.types.submodule to define structural restrictions for list elements
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            # This forces 'family' to be specified. If missing, evaluation throws an error.
            family = lib.mkOption {
              type = lib.types.str;
              description = "The precise font family name. REQUIRED.";
            };
            # This forces 'family' to be specified. If missing, evaluation throws an error.
            # Optional properties can fallback to default parameters automatically
            weight = lib.mkOption {
              type = lib.types.str;
              default = "Regular";
              description = "Optional font thickness weight.";
            };
            scale = lib.mkOption {
              type = lib.types.float;
              default = 1.0;
              description = "Optional font rendering size multiplier.";
            };
          };
        }
      );
    };
    fontPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [
        pkgs.doulos-sil
        pkgs.jigmo
        pkgs.noto-fonts-cjk-sans
        pkgs.nerd-fonts.fira-code
      ];
      description = "Font packages that you want to ensur ethat the are installed" ;
    };
    includeSystemFonts = lib.mkOption {
      type = lib.types.bool;
      default = true; # Enabled by default, set to false to completely isolate
      description = "Whether to include the host system's font configuration as a backup fallback.";
    };
    fontSize = lib.mkOption {
      type = lib.types.int;
      default = 10;
    };
    packageLuaDir = lib.mkOption {
      type = lib.types.path;
      description = ''
        lua directory underneatht he package installation path
        Usually should be set to $out/lua for the package

      '';
    };
    saveStateDir = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = /home/johndoe/sessions;
      description = ''
        location where session sate will be stored. By default it will be
        ~/.local/share/wezterm-sessions/state/
      '';
    };

  };

  # Provide your custom inline Lua configuration
  config = {
    package = inputs.wezterm.packages.${pkgs.stdenv.hostPlatform.system}.default;
    runtimePkgs = [ config.defaultProgram ];
    luaInfo = {
      theme = config.colorScheme;
      font_size = config.fontSize;
      fonts = config.fonts;
      default_prog = lib.meta.getExe config.defaultProgram;
      save_state_dir = config.saveStateDir;
      package_dir = "${placeholder "out"}/lua/";
    };
    "wezterm.lua".content = builtins.readFile ./wezterm.lua;
    buildCommand.copyLuaFolder = {
      # Forces this step to run before the framework's file-writing phase
      before = [ "constructFiles" ];

      # The raw bash scripting to execute
      data = ''
        # Create a destination directory inside the derivation output ($out)
        mkdir -p "$out/lua"

        # Recursively copy the entire contents of your local lua folder
        # Note: ${./lua} evaluates the path into the Nix store during build time
        cp -r ${./lua}/. "$out/lua/"
      '';
    };

    env.FONTCONFIG_FILE = lib.mkIf  (config.fontPackages != []) (makeFontEnv {
      fonts = config.fontPackages;
      includeSystem = true;
    });
  };
}
