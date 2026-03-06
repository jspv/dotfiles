# Dotfiles

Personal dotfiles, forked from [holman/dotfiles](https://github.com/holman/dotfiles). Topic-based organization with symlink conventions.

## Design Principles

1. **Repo is shared, read-only at runtime.** May be bind-mounted into devcontainers. Bootstrap creates per-environment symlinks from `$HOME` into the repo.
2. **Generated/environment-specific files go to `$HOME`**, never back into the repo. Use `~/.local/bin/` for generated scripts.
3. **`*.local` files** (gitignored) hold machine-specific config, sourced at the end of their parent.
4. **Cross-platform**: macOS (ARM + Intel) and Linux. Scripts detect OS and adapt.
5. **install.sh contract**: idempotent, writes only to `$HOME`, checks its own prerequisites.

See [docs/plans/2026-03-03-dotfiles-overhaul-design.md](docs/plans/2026-03-03-dotfiles-overhaul-design.md) for the full architecture.

## Structure & Conventions

**Topic directories** group config by purpose. Three special filename patterns are auto-discovered:

| Pattern | Behavior |
|---------|----------|
| `*.symlink` | Symlinked to `$HOME` with `.` prefix: `git/gitconfig.symlink` → `~/.gitconfig` |
| `install.sh` | Run by `script/install` (found up to 2 dirs deep). Must be idempotent. |
| `bin/*` | Available on `$PATH` via `~/bin` symlink |
| `*/path.zsh` | Sourced first in zshrc (PATH additions) |
| `*/*.zsh` | Auto-sourced in zshrc (config, aliases, env) |
| `*/completion.zsh` | Sourced last in zshrc (after compinit) |

**Key directories:**
- `script/` — bootstrap, install, lib.sh (shared helpers: `info`, `user`, `success`, `fail`, `link_files`)
- `functions/` — zsh autoloaded functions (added to `$fpath` in zshrc)
- `prezto/` — zsh framework config; `prezto/prezto` is the framework itself (submodule, symlinked to `~/.zprezto`)
- `config/` — `~/.config` subdirectories; `config/install.sh` creates `~/.config` and symlinks tracked subdirs individually

## File Layering

```
 Repo (shared, tracked)          $HOME (per-environment, untracked)
 ─────────────────────           ────────────────────────────────────
 git/gitconfig.symlink      →    ~/.gitconfig
                                 ~/.gitconfig.local       (user/creds)
 aliases.symlink             →    ~/.aliases
                                 ~/.aliases.local         (machine-specific)
 zsh/zshrc.symlink          →    ~/.zshrc
                                 ~/.zshrc.local           (machine-specific)
 bin/*                      →    ~/bin (symlink to repo)
                                 ~/.local/bin/            (generated scripts)
```

**PATH order:** `~/.local/bin` → `~/bin` → `$BREW_PREFIX/bin` → system

## Bootstrap & Maintenance

```bash
script/bootstrap [--force]  # First-time: create symlinks, ~/.local/bin, run dot
bin/dot                     # Ongoing: set-defaults, homebrew, all install.sh
bin/dot -e                  # Open dotfiles in $EDITOR
```

`dot` flow: detect OS → run `$os/set-defaults.sh` → `homebrew/install.sh` → `brew update` → `script/install`

## Shell Environment

**Zsh + Prezto + Powerlevel10k** (primary). **Bash** kept as working fallback.

Load order: `zshenv` → `zprofile` → `zshrc` → `zpreztorc` → `zlogin`

- `prezto/zprofile.symlink` — PATH (platform-detected), EDITOR=vim, login greeting (guarded)
- `zsh/zshrc.symlink` — p10k instant prompt, sets `$DOTFILES`, fpath (functions + topics), prezto init, `*.zsh` auto-discovery (path → general → completion), aliases, dircolors (guarded), sources `~/.zshrc.local`
- `aliases.symlink` — shared aliases (both bash and zsh); sources `~/.aliases.local`
- `bash/` — functional fallback; sources `~/.aliases` and `~/.bash_profile.local`

## Git Configuration

`git/gitconfig.symlink` — tracked directly with aliases, diff-so-fancy pager, colors, `push.default=current`, `fetch.prune=true`.

- URL rewrites: `gh:` → `git@github.com:`, https push → ssh
- Merge tool: opendiff (macOS FileMerge)
- `[include]` loads `~/.gitconfig.local` for user identity, credentials, per-machine overrides

## Gotchas

- **Prezto is a submodule**: lives at `prezto/prezto` in the repo. `prezto/install.sh` symlinks it to `~/.zprezto`. Initialize with `git submodule update --init --recursive`.
- **brew wrapper**: `bin/brew` strips pyenv shims from PATH before calling brew (auto-detects location).
- **No Brewfile**: packages are managed manually, not declaratively.
- **config/ uses per-subdir symlinks**: `config/install.sh` creates `~/.config` if needed and symlinks each tracked subdirectory individually (not the whole `~/.config`).
- **Pokemonsay greeting**: login shell shows a Pokemon fortune (hostname-dependent); guarded — skipped if tools missing.
- **`script/install` uses maxdepth 2**: install.sh files deeper than 2 levels won't be discovered.
- **Devcontainer sharing**: repo may be bind-mounted into containers. Each environment bootstraps independently. Generated scripts go to `~/.local/bin`, not into repo.

## Submodules

| Path | Purpose |
|------|---------|
| `samples/dotfiles-holman` | Upstream reference (not executed) |
| `vim/vim.symlink/bundle/vim-colors-solarized` | Vim colorscheme |
| `vim/vim.symlink/bundle/vim-sensible` | Vim sensible defaults |
| `vim/vim.symlink/bundle/base16-vim` | Base16 vim colors |
| `dircolors-solarized` | Terminal color definitions |
| `prezto/prezto` | Zsh framework (sorin-ionescu/prezto) |

Initialize with: `git submodule update --init --recursive` (or `git subpl`)

## Notable bin/ Scripts

- `devcontainer-init` — scaffolds `.devcontainer/` from templates in `~/src/devcontainers/`
- `git-nuke` — deletes branch locally and from origin
- `git-delete-local-merged` — cleans merged local branches
- `git-up` — pull with pretty log of changes
- `weasel` / `passive` — writing quality checkers (flag weasel words / passive voice)
- `crlf` — find/fix Windows line endings
- `set-defaults` — dispatches to OS-specific defaults script

## macOS Defaults (`macos/set-defaults.sh`)

Sets Terminal fonts (MesloLGS NF), iTerm2 prefs folder, Activity Monitor preferences. Run via `dot` or `bin/set-defaults`.
