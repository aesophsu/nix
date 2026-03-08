{
  description = "OpenClaw local";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-openclaw.url = "github:openclaw/nix-openclaw";
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      nix-openclaw,
      ...
    }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          nix-openclaw.overlays.default
          (final: prev: {
            openclaw-gateway = prev.openclaw-gateway.overrideAttrs (old: {
              installPhase = (old.installPhase or "") + ''
                # Baileys imports `long` at runtime without declaring it, so pnpm's
                # strict package layout leaves the package-local resolution path empty.
                long_src="$(find "$out/lib/openclaw/node_modules/.pnpm" -path "*/long@*/node_modules/long" -print | head -n 1)"
                baileys_pkg="$(find "$out/lib/openclaw/node_modules/.pnpm" -path "*/node_modules/@whiskeysockets/baileys" -print | head -n 1)"

                if [ -n "$long_src" ]; then
                  if [ ! -e "$out/lib/openclaw/node_modules/long" ]; then
                    ln -s "$long_src" "$out/lib/openclaw/node_modules/long"
                  fi

                  if [ -n "$baileys_pkg" ] && [ ! -e "$baileys_pkg/node_modules/long" ]; then
                    mkdir -p "$baileys_pkg/node_modules"
                    ln -s "$long_src" "$baileys_pkg/node_modules/long"
                  fi
                fi
              '';
            });
          })
        ];
      };
    in
    {
      homeConfigurations."sue" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          nix-openclaw.homeManagerModules.openclaw
          (
            { config, ... }:
            {
              home.username = "sue";
              home.homeDirectory = "/Users/sue";
              home.stateVersion = "24.11";
              programs.home-manager.enable = true;

              home.file.".openclaw/.env".source =
                config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.secrets/openclaw.env";

              programs.openclaw = {
                documents = ./documents;
                bundledPlugins.goplaces.enable = false;

                config = {
                  gateway = {
                    mode = "local";
                    auth = {
                      mode = "token";
                    };
                  };

                  agents.defaults.model.primary = "anthropic/claude-sonnet-4-5";

                  channels.telegram = {
                    tokenFile = "/Users/sue/.secrets/telegram-bot-token";
                    allowFrom = [
                      123456789
                    ];
                    groups = {
                      "*" = {
                        requireMention = true;
                      };
                    };
                  };
                };

                instances.default = {
                  enable = true;
                };
              };
            }
          )
        ];
      };
    };
}
