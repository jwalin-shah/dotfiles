{ config, pkgs, user, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
in

{
  home.packages = with pkgs; [
    # captain's extra Nix packages (available from nixpkgs)
    bat
    eza
    delta
    btop
    dust
    fastfetch
    ripgrep-all
    tree
  ];

  home.sessionVariables = {
    PATH = "${config.home.homeDirectory}/.cargo/bin:${config.home.homeDirectory}/.local/bin:${config.home.homeDirectory}/bin:/opt/homebrew/bin:$PATH";
  };

  programs.zsh.shellAliases = {
    # captain-specific aliases (merged with base home.nix aliases)
    ls = "eza";
    ll = "eza -l";
    la = "eza -la";
    lt = "eza --tree";

    # Captain's agent launcher aliases.
    # Unlike upstream's `cc = "claude --dangerously-skip-permissions"`,
    # these just invoke the launcher wrapper which handles auth and routing.
    c = "claude";
    cx = "codex";
    gha = "npx -y gh-axi";
    cda = "npx -y chrome-devtools-axi";
    lva = "npx -y lavish-axi";
  };

  # Symlinks for captain-specific config files (under captain/config/)
  home.file.".config/opencode/opencode.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/captain/config/opencode.json";
  home.file.".config/jw/models.env".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/captain/config/models.env";
  home.file.".headroom-tr-proxy.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/captain/config/headroom-tr-proxy.toml";
}
