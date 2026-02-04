{
  description = "Milan Sue's nix configuration for macOS (MacBook Air M4)";

  outputs = inputs: import ./outputs inputs;

  nixConfig = {
    # 不提示「Git tree has uncommitted changes」（若希望可复现构建，请保持工作区干净并提交）
    warn-dirty = false;
    # 国内网络拉取 GitHub 时使用本机代理（需先启动 mihomo）
    http-proxy = "http://127.0.0.1:7890";
    https-proxy = "http://127.0.0.1:7890";
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

    haumea = {
      url = "github:nix-community/haumea/v0.2.2";
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

    # 以下 path 输入避免 darwin-rebuild 时 Nix daemon 从 GitHub 拉取（daemon 不走代理会 SSL 失败）
    # 首次在「已开代理」的终端执行：
    #   git clone https://github.com/openclaw/nix-openclaw /Users/sue/nix-openclaw
    #   git clone https://github.com/numtide/flake-utils /Users/sue/flake-utils && (cd /Users/sue/flake-utils && git checkout 11707dc2f618dd54ca8739b309ec4fc024de578b)
    #   git clone https://github.com/openclaw/nix-steipete-tools /Users/sue/nix-steipete-tools
    flake-utils.url = "path:/Users/sue/flake-utils";
    nix-steipete-tools = {
      url = "path:/Users/sue/nix-steipete-tools";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-openclaw = {
      url = "path:/Users/sue/nix-openclaw";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      inputs.home-manager.follows = "home-manager";
      inputs.nix-steipete-tools.follows = "nix-steipete-tools";
    };

    # 如需 secrets 管理，可添加自己的私有仓库
    # mysecrets = {
    #   url = "git+ssh://git@github.com/YOUR_USER/YOUR_SECRETS_REPO.git?shallow=1";
    #   flake = false;
    # };
  };
}
