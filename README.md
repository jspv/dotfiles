# Dotfiles

Personal dotfiles forked from [holman/dotfiles](https://github.com/holman/dotfiles). Topic-based organization where each directory groups related config, scripts, and shell extensions.

## Fresh System Install

```bash
# 1. Clone the repo
git clone https://github.com/jspv/dotfiles.git ~/src/dotfiles
cd ~/src/dotfiles

# 2. Initialize submodules (vim plugins, dircolors, etc.)
git submodule update --init --recursive

# 3. Bootstrap
script/bootstrap
```

`script/bootstrap` will prompt for confirmation, then:

1. Verify `git` is installed (required). Warn if `zsh` or `fortune` are missing (optional).
2. Create a `~/.dotfiles` symlink pointing to the repo (if not already present).
3. Find all `*.symlink` files (up to 2 directories deep) and symlink each to `$HOME` with a `.` prefix — e.g. `git/gitconfig.symlink` becomes `~/.gitconfig`. If a file already exists at the destination, you'll be prompted to skip, overwrite, or back it up.
4. Symlink `bin/` to `~/bin`.
5. Create `~/.local/bin/` (for per-machine generated scripts).
6. Run `dot`, which triggers all topic installers (see below).

Use `script/bootstrap --force` to skip the confirmation prompt and overwrite existing symlinks without asking.

## Ongoing Maintenance

```bash
dot            # Re-run installers, update Homebrew, apply OS defaults
dot -e         # Open dotfiles in $EDITOR
```

`dot` does the following, in order:

1. Run OS-specific defaults (e.g. `macos/set-defaults.sh` on macOS).
2. Run `homebrew/install.sh` (installs Homebrew on macOS; skips on Linux).
3. Run `brew update` if Homebrew is available.
4. Run `script/install`, which finds and executes every `install.sh` in topic directories (up to 2 levels deep).

All installers are idempotent — `dot` is safe to run anytime.

## Topic Directories

Each directory is a "topic" — a self-contained group of config for one tool or purpose. Topics use special filename conventions that are auto-discovered:

| Pattern | What happens |
|---------|-------------|
| `*.symlink` | Symlinked to `$HOME` with a `.` prefix by `script/bootstrap` |
| `install.sh` | Executed by `script/install` (must be idempotent) |
| `bin/*` | On `$PATH` via the `~/bin` symlink |
| `*/path.zsh` | Sourced **first** by zshrc — for PATH additions |
| `*/*.zsh` | Auto-sourced by zshrc — config, aliases, env vars |
| `*/completion.zsh` | Sourced **last** by zshrc — after compinit |

### Adding a New Tool

To add config for a new tool (e.g. `tmux`), create a topic directory with any combination of these files:

```
tmux/
├── tmux.conf.symlink    # Symlinked to ~/.tmux.conf by bootstrap
├── install.sh           # Install tmux via brew, etc.
├── path.zsh             # Add to PATH if needed
├── tmux.zsh             # Shell config, aliases, env vars
└── completion.zsh       # Completion setup
```

All files are optional — include only what you need. No manual wiring is required: `*.symlink` files are found by `script/bootstrap`, `install.sh` files by `script/install`, and `*.zsh` files are auto-sourced by zshrc on every shell startup.

## Managing PATH and Environment

### PATH Order

PATH is set in `prezto/zprofile.symlink` (which becomes `~/.zprofile`), loaded on login shells. Priority order:

```
~/.local/bin              # Per-machine generated scripts
~/bin                     # Repo's bin/ directory (symlinked)
/opt/homebrew/{,s}bin     # Homebrew (Apple Silicon)
/usr/local/{,s}bin        # Homebrew (Intel) or system
/usr/{,s}bin              # System
```

If Homebrew is available, brew-managed npm and ruby binaries are also added.

For non-login interactive shells (e.g. shells opened inside tmux or editors), `homebrew/path.zsh` runs `brew shellenv` to ensure Homebrew is on PATH.

### Adding PATH Entries

Create a `path.zsh` in your topic directory. These are sourced before all other `*.zsh` files, so PATH is ready before anything depends on it:

```zsh
# mytool/path.zsh
export PATH="$HOME/.mytool/bin:$PATH"
```

### Adding Environment Variables or Aliases

Use a regular `*.zsh` file in your topic directory:

```zsh
# mytool/mytool.zsh
export MYTOOL_HOME="$HOME/.mytool"
alias mt="mytool"
```

### The `$DOTFILES` Variable

`$DOTFILES` is exported by zshrc and points to the repo root (`~/.dotfiles`). Use it in `*.zsh` files to reference other files in the repo.

## Machine-Specific Config

Several dotfiles check for a `.local` counterpart in `$HOME` and source it if it exists. These files are not part of the repo — you create them yourself on each machine for local overrides:

| Dotfile (symlinked from repo) | Sources if it exists |
|-------------------------------|----------------------|
| `~/.zshenv` | `~/.zshenv.local` |
| `~/.zprofile` | `~/.zprofile.local` |
| `~/.zshrc` | `~/.zshrc.local` |
| `~/.aliases` | `~/.aliases.local` |
| `~/.bash_profile` | `~/.bash_profile.local` |
| `~/.gitconfig` | `~/.gitconfig.local` (via git's `[include]`) |

The shell files use existence checks (`[[ -f ... ]] &&` or `[ -f ... ]`) so nothing breaks if the `.local` file doesn't exist. Git's `[include]` silently skips missing files.

Use `.local` files for credentials, hostname-specific settings, extra PATH entries, or anything that shouldn't be committed:

```ini
# ~/.gitconfig.local
[user]
    name = Your Name
    email = you@example.com
```

```zsh
# ~/.zprofile.local — set pokemonsay pokemon per-host
pokemon=Pikachu
```

## Shell Environment

**Zsh + Prezto + Powerlevel10k** is the primary shell. Bash is kept as a working fallback.

### Zsh Load Order

```
zshenv → zprofile → zshrc → zpreztorc → zlogin
```

- **zshenv** (`prezto/zshenv.symlink`) — Sources `~/.zprofile` for non-login non-interactive shells. Sources `~/.zshenv.local` if it exists.
- **zprofile** (`prezto/zprofile.symlink`) — PATH setup (platform-detected), `EDITOR=vim`, Homebrew shell environment, login greeting (fortune + pokemonsay, skipped if either command is missing). Sources `~/.zprofile.local` if it exists.
- **zshrc** (`zsh/zshrc.symlink`) — In order:
  1. Powerlevel10k instant prompt (cached, for fast startup)
  2. Set `$DOTFILES` to `~/.dotfiles`
  3. Build `fpath` — prepend `$DOTFILES/functions` and all topic directories
  4. Source Prezto (`~/.zprezto/init.zsh`) if present
  5. Autoload custom functions from `$DOTFILES/functions`
  6. Auto-discover `*.zsh` files: `path.zsh` first, then general `*.zsh`, then `completion.zsh` last
  7. Source `~/.aliases` if it exists
  8. Set up dircolors (macOS: `LSCOLORS`; Linux: `dircolors` with solarized theme if available)
  9. Source `~/.zshrc.local` if it exists
  10. Source `~/.p10k.zsh` if it exists (Powerlevel10k config)

### Auto-Discovery Details

The `*.zsh` auto-discovery uses a shallow glob (`$DOTFILES/*/*.zsh`) — one level deep only. This naturally excludes nested directories like `samples/dotfiles-holman/`, submodule paths under `vim/vim.symlink/bundle/`, and `.git/`.

Three-pass sourcing order:

1. `*/path.zsh` — PATH additions, before anything depends on them
2. All other `*.zsh` (except path.zsh and completion.zsh) — general config
3. `*/completion.zsh` — completion setup, after Prezto's compinit has run

### Bash

Bash config lives in `bash/bash_profile.symlink` (becomes `~/.bash_profile`). It sets up its own PATH, sources `~/.aliases`, and loads `~/.bash_profile.local` if it exists. It works independently of the zsh setup.

## Cross-Platform Support

Scripts detect the OS and adapt:

- **macOS** (ARM + Intel): Homebrew paths auto-detected (`/opt/homebrew` vs `/usr/local`), `macos/set-defaults.sh` applies Terminal fonts and iTerm2 preferences.
- **Linux**: Homebrew install skipped, `dircolors` loaded for terminal colors, iterm2 shell integration safely skipped (self-guarded with an `$OSTYPE` check).

## Writing install.sh Scripts

Every `install.sh` must be:

- **Idempotent** — safe to run repeatedly without side effects
- **Self-guarding** — check prerequisites and skip gracefully if not met
- **Home-only** — write to `$HOME` only, never back into the repo

```bash
#!/bin/bash
# mytool/install.sh
source "$(dirname "$0")/../script/lib.sh"

if ! command -v mytool &>/dev/null; then
  info "Installing mytool..."
  brew install mytool
  success "mytool installed"
else
  info "mytool already installed"
fi
```

`script/lib.sh` provides helper functions: `info`, `user`, `success`, `fail`, and `link_files` (smart symlinking with skip/overwrite/backup prompts).

Generated scripts (wrappers, shims) should go in `~/.local/bin/`, not in the repo. See `pokemonsay/install.sh` for an example.

## Repository Structure

```
dotfiles/
├── script/              # Bootstrap, install, shared helpers
│   ├── bootstrap        # First-time setup: symlinks, ~/bin, ~/.local/bin
│   ├── install          # Discovers and runs all topic install.sh files
│   └── lib.sh           # Shared helpers: info(), success(), fail(), link_files()
├── bin/                 # Scripts on $PATH (symlinked to ~/bin)
├── functions/           # Zsh autoloaded functions (on $fpath)
├── zsh/                 # Zsh config: zshrc.symlink, iterm2 shell integration
├── prezto/              # Prezto framework config: zprofile, zpreztorc, zshenv
├── git/                 # Git config: gitconfig.symlink, gitignore.symlink
├── homebrew/            # Homebrew installer + path.zsh
├── config/              # ~/.config subdirs, symlinked individually by config/install.sh
├── macos/               # macOS-specific defaults (set-defaults.sh)
├── bash/                # Bash fallback config (bash_profile.symlink)
├── vim/                 # Vim config + plugins (submodules)
├── fonts/               # Custom fonts (installed to ~/Library/Fonts on macOS)
├── pokemonsay/          # Login greeting (generates wrapper in ~/.local/bin)
├── samples/             # Upstream holman reference (not executed)
└── dircolors-solarized/ # Terminal color definitions (submodule)
```

## Submodules

Initialize with `git submodule update --init --recursive` (or the git alias `git subpl`).

| Path | Purpose |
|------|---------|
| `samples/dotfiles-holman` | Upstream reference (not executed) |
| `vim/vim.symlink/bundle/vim-colors-solarized` | Vim colorscheme |
| `vim/vim.symlink/bundle/vim-sensible` | Vim sensible defaults |
| `vim/vim.symlink/bundle/base16-vim` | Base16 vim colors |
| `dircolors-solarized` | Terminal color definitions |
| `prezto/prezto` | Zsh framework (sorin-ionescu/prezto) |

## Gotchas

- **Prezto is a submodule** — lives at `prezto/prezto` in the repo, symlinked to `~/.zprezto` by `prezto/install.sh`. Initialized automatically by `git submodule update --init --recursive`
- **`script/install` uses maxdepth 2** — `install.sh` files deeper than 2 directory levels won't be discovered
- **`*/*.zsh` is one level deep** — files in nested subdirs (e.g. `vim/vim.symlink/bundle/`) are not auto-sourced
- **`bin/brew` wrapper** — strips pyenv shims from PATH before calling the real `brew` binary
- **No Brewfile** — Homebrew packages are managed manually, not declaratively
- **Devcontainer safe** — repo can be bind-mounted into containers; each environment runs `script/bootstrap` independently; generated scripts go to `~/.local/bin`, not into the repo
