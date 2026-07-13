# Homebrew brews/casks/npm-globals usage audit

Method: `~/.zsh_history` (1356 lines) command counts, dotfiles/project grep
for build-tool usage, `homebrew.onActivation.cleanup = "zap"` already
prunes undeclared brews, so the risk here is declared-but-dead entries.

## Clear evidence of use
- gh (6), go (5), infisical (4), jq (3), opencode (7), uv (8), tailscale (25),
  tmux (17), tree (14), zig (1, matches ~/projects but no build.zig found -
  see below), zoxide (1)
- bat/eza/fd/rg(grep)/trash(rm) - all aliased (`cat`, `ls`, `find`, `grep`, `rm`
  in home.nix), history shows heavy alias usage (cat 32, rm 34, grep 6, ls 3,
  find 2) confirming real use even though raw binary name doesn't appear
- clang-format, cmake - referenced in `dotfiles/templates/c/Makefile`
- swift-format - referenced in `dotfiles/templates/swift/Makefile` and
  `voice-engine-swift/Makefile` (real Swift project exists)
- golangci-lint, gofumpt - referenced in `dotfiles/templates/go/Makefile`
- direnv (2), fzf (0 direct but standard fzf keybindings don't show as literal
  commands), tuxedo - referenced in captain/GLOBAL.md and verification-contract.md
  as active todo.txt workflow
- dust, ncdu, wget, yq - referenced in captain/agent-rules docs as the
  documented tool set (dust is explicitly "for humans" per TOOL_REGISTRY.md,
  agents must use `du -s` instead - so dust's near-zero history count is
  expected, it's a human-only tool by design)
- borders - active in `config/aerospace/aerospace.toml` (`exec-and-forget
  borders active_color=...`), loads on aerospace startup, won't show in shell
  history since it's launched by aerospace itself
- node - `~/projects/personal-assistant/package.json` exists; also required
  transitively for npm-managed gh-axi/chrome-devtools-axi/lavish-axi
- container - not yet installed (rb pending sudo), can't audit usage yet,
  newly added per captain's explicit request this session
- ffmpeg, jq, wget, coreutils - standard-utility category, low history
  signal is normal for tools invoked by scripts rather than typed directly

## No clear evidence of use (candidates to ask captain about, not auto-remove)
- btop (1 hit) - low but nonzero, likely used interactively/visually rather
  than scripted, not a strong removal candidate
- typst - zero history hits, zero dotfiles/project references found despite
  `modern-resume` being a Typst project per CLAUDE.md project map; worth
  checking `~/projects/modern-resume` directly (out of scope for this pass)
- rustup, python@3.14, ruff, shellcheck - zero history hits; python@3.14 is
  almost certainly load-bearing (task #2's entire pip/uv migration plan
  depends on it) despite no raw `python3.14` history hits (likely invoked via
  `python3`/`uv` wrappers, not typed literally)
- fzf - zero literal hits, but fzf is typically invoked via Ctrl-R/Ctrl-T
  keybindings, not typed as a command, so absence from history is expected
  and not meaningful signal either way

## Couldn't determine
- gh-axi, chrome-devtools-axi, lavish-axi (npm globals) - zero history hits
  for either the binary names or the `gha`/`cda`/`lva` aliases; too new
  (installed this session per earlier conversation) for history to be
  meaningful yet
- aerospace, cursor, ghostty, karabiner-elements, lulu, monitorcontrol,
  raycast (casks) - GUI apps, shell history is not a meaningful signal;
  needs the separate app-config survey (task #11) instead

## Bottom line
No strong removal candidates surfaced. The declared list is well-justified
by cross-referencing docs/templates/configs rather than raw shell history
alone (many entries are GUI apps, human-only tools, or invoked via aliases/
build systems that don't show literal binary names). Only loose thread:
verify `typst` is actually used by `modern-resume` or drop it.
