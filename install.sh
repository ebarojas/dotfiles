#!/bin/bash

# Dotfiles Installation Script
# This script symlinks dotfiles, installs packages, and sets up the shell

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the directory where this script is located
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

echo -e "${GREEN}Starting dotfiles installation...${NC}"

# Function to create symlink
symlink_file() {
    local source_file="$1"
    local target_file="$2"
    
    if [ -e "$target_file" ] || [ -L "$target_file" ]; then
        if [ -L "$target_file" ] && [ "$(readlink "$target_file")" = "$source_file" ]; then
            echo -e "${YELLOW}Symlink already exists: $target_file${NC}"
            return 0
        else
            echo -e "${YELLOW}Backing up existing file: $target_file${NC}"
            mv "$target_file" "${target_file}.backup.$(date +%Y%m%d_%H%M%S)"
        fi
    fi
    
    echo -e "${GREEN}Creating symlink: $target_file -> $source_file${NC}"
    ln -s "$source_file" "$target_file"
}

# Step 1: Symlink dotfiles
echo -e "\n${GREEN}=== Step 1: Symlinking dotfiles ===${NC}"

# List of dotfiles to symlink
DOTFILES=(
    ".zshrc"
    ".bashrc"
    ".vimrc"
    ".gitconfig"
    ".tmux.conf"
)

for dotfile in "${DOTFILES[@]}"; do
    if [ -f "$DOTFILES_DIR/$dotfile" ]; then
        # Special handling for .ssh_config -> ~/.ssh/config
        if [ "$dotfile" = ".ssh_config" ]; then
            # Ensure .ssh directory exists
            mkdir -p "$HOME/.ssh"
            symlink_file "$DOTFILES_DIR/$dotfile" "$HOME/.ssh/config"
        else
            symlink_file "$DOTFILES_DIR/$dotfile" "$HOME/$dotfile"
        fi
    else
        echo -e "${RED}Warning: $dotfile not found in dotfiles directory${NC}"
    fi
done

# Handle nvim config (symlink entire .config dir -> ~/.config/nvim)
if [ -d "$DOTFILES_DIR/.config" ]; then
    mkdir -p "$HOME/.config"
    symlink_file "$DOTFILES_DIR/.config" "$HOME/.config/nvim"
fi

# Step 2: Set up local git config
echo -e "\n${GREEN}=== Step 2: Setting up local git config ===${NC}"
if [ ! -f "$HOME/.gitconfig.local" ]; then
    read -p "Enter your git email: " git_email
    if [ -z "$git_email" ]; then
        echo -e "${RED}Email is required. Exiting.${NC}"
        exit 1
    fi
    echo -e "[user]\n\temail = $git_email" > "$HOME/.gitconfig.local"
    echo -e "${GREEN}Created ~/.gitconfig.local${NC}"
else
    echo -e "${YELLOW}~/.gitconfig.local already exists. Skipping.${NC}"
fi

# Step 3: Install packages
echo -e "\n${GREEN}=== Step 2: Installing packages ===${NC}"

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS - use Homebrew
    if ! command -v brew &> /dev/null; then
        echo -e "${YELLOW}Homebrew not found. Installing Homebrew...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    echo -e "${GREEN}Installing packages using Homebrew...${NC}"
    # Extract package names from packages.txt (first column, skip lines with "deinstall")
    if [ -f "$DOTFILES_DIR/packages.txt" ]; then
        # For macOS, we'll install common packages that have Homebrew equivalents
        # You may want to create a separate brew-packages.txt or manually specify packages
        echo -e "${YELLOW}Note: packages.txt appears to be for Debian/Ubuntu.${NC}"
        echo -e "${YELLOW}For macOS, consider creating a separate brew-packages.txt file.${NC}"
        echo -e "${YELLOW}Skipping package installation from packages.txt on macOS.${NC}"
    fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux - use apt (Debian/Ubuntu)
    if command -v apt-get &> /dev/null; then
        echo -e "${GREEN}Installing packages using apt...${NC}"
        if [ -f "$DOTFILES_DIR/packages.txt" ]; then
            # Extract package names, skipping comments and empty lines
            PACKAGES=$(grep -v '^#' "$DOTFILES_DIR/packages.txt" | grep -v '^$' | tr '\n' ' ')
            if [ -n "$PACKAGES" ]; then
                echo -e "${YELLOW}This will install the following packages:${NC}"
                echo -e "${YELLOW}$PACKAGES${NC}"
                echo -e "${YELLOW}Continue? (y/n)${NC}"
                read -r response
                if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
                    # Ensure curl is installed (needed for repository setup)
                    if ! command -v curl &> /dev/null; then
                        echo -e "${YELLOW}curl not found. Installing curl...${NC}"
                        sudo apt-get update
                        sudo apt-get install -y curl
                    fi
                    # Check if heroku is in the package list and set up repository if needed
                    if echo "$PACKAGES" | grep -q "heroku"; then
                        if ! grep -q "cli-assets.heroku.com" /etc/apt/sources.list.d/* 2>/dev/null && [ ! -f /etc/apt/sources.list.d/heroku.list ]; then
                            echo -e "${GREEN}Setting up Heroku repository...${NC}"
                            curl https://cli-assets.heroku.com/install-ubuntu.sh | sh
                        else
                            echo -e "${YELLOW}Heroku repository already configured.${NC}"
                        fi
                    fi
                    # Check if vagrant is in the package list and set up repository if needed
                    if echo "$PACKAGES" | grep -q "vagrant"; then
                        if ! grep -q "apt.releases.hashicorp.com" /etc/apt/sources.list.d/* 2>/dev/null && [ ! -f /etc/apt/sources.list.d/hashicorp.list ]; then
                            echo -e "${GREEN}Setting up HashiCorp repository for Vagrant...${NC}"
                            curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
                            echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
                        else
                            echo -e "${YELLOW}HashiCorp repository already configured.${NC}"
                        fi
                    fi
                    # MongoDB (mongosh) — uses bookworm repo, trixie not yet supported
                    if echo "$PACKAGES" | grep -q "mongosh"; then
                        if [ ! -f /etc/apt/sources.list.d/mongodb-org-8.0.list ]; then
                            echo -e "${GREEN}Setting up MongoDB repository...${NC}"
                            curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | sudo gpg --dearmor -o /etc/apt/keyrings/mongodb-server-8.0.gpg
                            echo "deb [ arch=amd64,arm64 signed-by=/etc/apt/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/debian bookworm/mongodb-org/8.0 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
                        else
                            echo -e "${YELLOW}MongoDB repository already configured.${NC}"
                        fi
                    fi
                    # VirtualBox — Oracle repo
                    if echo "$PACKAGES" | grep -q "virtualbox"; then
                        if [ ! -f /etc/apt/sources.list.d/virtualbox.list ]; then
                            echo -e "${GREEN}Setting up VirtualBox repository...${NC}"
                            curl -fsSL https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo gpg --yes --dearmor -o /usr/share/keyrings/oracle-virtualbox-2016.gpg
                            echo "deb [arch=amd64 signed-by=/usr/share/keyrings/oracle-virtualbox-2016.gpg] https://download.virtualbox.org/virtualbox/debian trixie contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list
                        else
                            echo -e "${YELLOW}VirtualBox repository already configured.${NC}"
                        fi
                    fi
                    # Google Chrome
                    if echo "$PACKAGES" | grep -q "google-chrome"; then
                        if [ ! -f /etc/apt/sources.list.d/google-chrome.list ]; then
                            echo -e "${GREEN}Setting up Google Chrome repository...${NC}"
                            curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg
                            echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
                        else
                            echo -e "${YELLOW}Google Chrome repository already configured.${NC}"
                        fi
                    fi
                    # Spotify
                    if echo "$PACKAGES" | grep -q "spotify"; then
                        if [ ! -f /etc/apt/sources.list.d/spotify.list ]; then
                            echo -e "${GREEN}Setting up Spotify repository...${NC}"
                            curl -sS https://download.spotify.com/debian/pubkey_5384CE82BA52C83A.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/spotify.gpg
                            echo "deb [signed-by=/etc/apt/keyrings/spotify.gpg] https://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
                        else
                            echo -e "${YELLOW}Spotify repository already configured.${NC}"
                        fi
                    fi
                    # Sublime Text
                    if echo "$PACKAGES" | grep -q "sublime-text"; then
                        if [ ! -f /etc/apt/sources.list.d/sublime-text.sources ]; then
                            echo -e "${GREEN}Setting up Sublime Text repository...${NC}"
                            wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo tee /etc/apt/keyrings/sublimehq-pub.asc > /dev/null
                            printf 'Types: deb\nURIs: https://download.sublimetext.com/\nSuites: apt/stable/\nSigned-By: /etc/apt/keyrings/sublimehq-pub.asc\n' | sudo tee /etc/apt/sources.list.d/sublime-text.sources
                        else
                            echo -e "${YELLOW}Sublime Text repository already configured.${NC}"
                        fi
                    fi
                    sudo apt-get update
                    failed=()
                    for pkg in $PACKAGES; do
                        if ! sudo apt-get install -y "$pkg"; then
                            echo -e "${RED}Failed to install: $pkg${NC}"
                            failed+=("$pkg")
                        fi
                    done
                    if [ ${#failed[@]} -gt 0 ]; then
                        echo -e "\n${RED}The following packages failed to install:${NC}"
                        for pkg in "${failed[@]}"; do
                            echo -e "${RED}  - $pkg${NC}"
                        done
                    fi
                else
                    echo -e "${YELLOW}Skipping package installation.${NC}"
                fi
            fi
        fi
    else
        echo -e "${RED}apt-get not found. Please install packages manually.${NC}"
    fi
else
    echo -e "${YELLOW}Unknown OS: $OSTYPE. Skipping package installation.${NC}"
fi

# Step 3: Set up shell
echo -e "\n${GREEN}=== Step 3: Setting up shell ===${NC}"

# Set up Vundle for vim if .vimrc exists and references it
if [ -f "$HOME/.vimrc" ] && grep -q "Vundle" "$HOME/.vimrc"; then
    if [ ! -d "$HOME/.vim/bundle/Vundle.vim" ]; then
        echo -e "${GREEN}Installing Vundle for vim...${NC}"
        mkdir -p "$HOME/.vim/bundle"
        git clone https://github.com/VundleVim/Vundle.vim.git "$HOME/.vim/bundle/Vundle.vim"
    else
        echo -e "${YELLOW}Vundle is already installed.${NC}"
    fi
    
    # Install vim plugins
    echo -e "${GREEN}Installing vim plugins...${NC}"
    vim +PluginInstall +qall 2>/dev/null || echo -e "${YELLOW}Could not install vim plugins automatically. Run 'vim +PluginInstall +qall' manually.${NC}"
fi

# Set up vim-plug for Neovim if init.vim exists and references it
if [ -f "$HOME/.config/nvim/init.vim" ] && grep -q "plug#begin" "$HOME/.config/nvim/init.vim"; then
    PLUG_PATH="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/autoload/plug.vim"
    if [ ! -f "$PLUG_PATH" ]; then
        echo -e "${GREEN}Installing vim-plug for Neovim...${NC}"
        mkdir -p "$(dirname "$PLUG_PATH")"
        curl -fLo "$PLUG_PATH" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    else
        echo -e "${YELLOW}vim-plug is already installed.${NC}"
    fi
    
    # Install neovim plugins
    if command -v nvim &> /dev/null; then
        echo -e "${GREEN}Installing Neovim plugins...${NC}"
        nvim +PlugInstall +qall 2>/dev/null || echo -e "${YELLOW}Could not install Neovim plugins automatically. Run 'nvim +PlugInstall +qall' manually.${NC}"
    fi
fi

# Set zsh as default shell (if zsh is installed)
if command -v zsh &> /dev/null; then
    CURRENT_SHELL=$(echo $SHELL)
    ZSH_PATH=$(which zsh)
    
    if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
        echo -e "${GREEN}Setting zsh as default shell...${NC}"
        echo -e "${YELLOW}You may need to enter your password.${NC}"
        chsh -s "$ZSH_PATH" || echo -e "${YELLOW}Could not change default shell. Run 'chsh -s $(which zsh)' manually.${NC}"
    else
        echo -e "${YELLOW}zsh is already the default shell.${NC}"
    fi
fi

echo -e "\n${GREEN}=== Installation complete! ===${NC}"
echo -e "${GREEN}Please restart your terminal or run 'source ~/.zshrc' to apply changes.${NC}"

# TODO: Should find a way to install claude code
