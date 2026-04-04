#!/bin/bash

# Initial Setup Script
# This script handles first-time setup: Git, SSH keys, cloning, and installation

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting initial dotfiles setup...${NC}\n"

# Step 1: Check/Install Git
echo -e "${GREEN}=== Step 1: Checking Git ===${NC}"
if command -v git &> /dev/null; then
    echo -e "${YELLOW}Git is already installed.${NC}"
else
    echo -e "${YELLOW}Git not found. Installing...${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew &> /dev/null; then
            brew install git
        else
            echo -e "${RED}Homebrew not found. Please install Git manually.${NC}"
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y git
        else
            echo -e "${RED}apt-get not found. Please install Git manually.${NC}"
            exit 1
        fi
    else
        echo -e "${RED}Unknown OS. Please install Git manually.${NC}"
        exit 1
    fi
fi

# Step 2: Check/Generate SSH keys
echo -e "\n${GREEN}=== Step 2: Checking SSH keys ===${NC}"
if [ -f "$HOME/.ssh/cheve_id_ed25519" ] || [ -f "$HOME/.ssh/id_rsa" ]; then
    echo -e "${YELLOW}SSH key already exists.${NC}"
else
    echo -e "${YELLOW}No SSH key found. Generating one...${NC}"
    read -p "Enter your email for the SSH key: " email
    if [ -z "$email" ]; then
        echo -e "${RED}Email is required. Exiting.${NC}"
        exit 1
    fi
    ssh-keygen -t ed25519 -C "$email" -f "$HOME/.ssh/cheve_id_ed25519"
    echo -e "${GREEN}SSH key generated!${NC}"
    echo -e "${YELLOW}Your public key:${NC}"
    cat "$HOME/.ssh/cheve_id_ed25519.pub"
    echo -e "\n${YELLOW}Please add this key to your GitHub account before continuing.${NC}"
    echo -e "${YELLOW}Press Enter when done...${NC}"
    read -r
fi

# Step 3: Get repository URL and clone
echo -e "\n${GREEN}=== Step 3: Cloning dotfiles repository ===${NC}"
read -p "Enter your dotfiles repository URL (e.g., git@github.com:user/dotfiles.git): " repo_url
if [ -z "$repo_url" ]; then
    echo -e "${RED}Repository URL is required. Exiting.${NC}"
    exit 1
fi

DOTFILES_DIR="$HOME/dotfiles"
if [ -d "$DOTFILES_DIR" ]; then
    echo -e "${YELLOW}Directory $DOTFILES_DIR already exists.${NC}"
    read -p "Remove it and clone fresh? (y/n): " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        rm -rf "$DOTFILES_DIR"
    else
        echo -e "${YELLOW}Using existing directory.${NC}"
    fi
fi

if [ ! -d "$DOTFILES_DIR" ]; then
    echo -e "${GREEN}Cloning repository...${NC}"
    git clone "$repo_url" "$DOTFILES_DIR"
else
    echo -e "${YELLOW}Directory exists. Skipping clone.${NC}"
fi

