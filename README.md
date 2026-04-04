# My Dotfiles

## First-time Setup

For a fresh machine, run `initial_setup.sh` to handle Git installation, SSH key generation, cloning, and installation:

```bash
curl -fsSL https://raw.githubusercontent.com/ebarojas/dotfiles/main/initial_setup.sh | bash
```

Or download and run:
```bash
wget https://raw.githubusercontent.com/yourname/dotfiles/main/initial_setup.sh
chmod +x initial_setup.sh
./initial_setup.sh
```

## Setup (if already cloned)

```bash
cd ~/dotfiles
./install.sh
```

## What it does

The `install.sh` script will:

1. **Symlink dotfiles** - Creates symlinks for `.zshrc`, `.bashrc`, `.vimrc`, `.gitconfig`, and `.tmux.conf` in your home directory (backs up existing files)
2. **Set up local git config** - Prompts for your email and writes it to `~/.gitconfig.local` (not committed to the repo — see [Git config](#git-config))
3. **Install packages** - Installs packages from `packages.txt` (Linux/apt) or via Homebrew (macOS)
4. **Set up shell** - Installs Vundle, sets zsh as default shell

## Git config

`.gitconfig` in this repo does not include an email address. On first run, `install.sh` will prompt for your email and create `~/.gitconfig.local`:

```ini
[user]
    email = you@example.com
```

This file is outside the repo and never committed. To set it up manually:

```bash
echo -e "[user]\n\temail = you@example.com" > ~/.gitconfig.local
```

## Usage

Just run `./install.sh` and follow the prompts. The script will:
- Back up any existing dotfiles before creating symlinks
- Ask for confirmation before installing packages
- Automatically set up oh-my-zsh and Vundle if needed
- need to run PlugInstall in nvim to install all of the init.vim folders

## Upkeep

To update your package lists periodically:

**Linux (apt):**
```bash
apt-mark showmanual > packages.txt
```

**macOS (Homebrew):**
```bash
brew leaves > brew-packages.txt
```

Commit the updated files to keep your dotfiles in sync.

