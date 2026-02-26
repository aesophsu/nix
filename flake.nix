{
  description = "Milan Sue's nix configuration for macOS (MacBook Air M4)";

  outputs = inputs: import ./outputs inputs;

  nixConfig = {
    # No "uncommitted changes" warning (keep tree clean for reproducible builds)
    warn-dirty = false;
    # First deploy without proxy (path inputs + mirrors). For nix flake update set proxy in ~/.config/nix/nix.conf or run mihomo first:
    #   http-proxy = "http://127.0.0.1:7890"
    #   https-proxy = "http://127.0.0.1:7890"
    # extra-substituters = [ "https://nix-community.cachix.org" ];
    # extra-trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nuenv = {
      url = "github:DeterminateSystems/nuenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Optional: add your own private repo for secrets
    # mysecrets = {
    #   url = "git+ssh://git@github.com/YOUR_USER/YOUR_SECRETS_REPO.git?shallow=1";
    #   flake = false;
    # };
  };
}
