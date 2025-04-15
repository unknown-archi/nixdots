#!/usr/bin/env bash

# Fedora Setup Script for Mathieu's NixOS Config Replication
# Version: 1.0

# --- Configuration ---
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_HOME="$HOME"           
STOW_DIR="$USER_HOME/.files"
USERNAME="$(whoami)"

# User customizable configuration
GIT_USER_NAME="Mathieu"  # Change this if needed
GIT_USER_EMAIL="unknown-archi@users.noreply.github.com"  # Change this if needed
EDITOR_CMD="nano"  # Default editor (nano, vim, nvim)

# Ensure the permanent Stow directory exists
mkdir -p "$STOW_DIR"

# --- Helper Functions ---
print_info() {
    echo -e "\n\e[1;34m[INFO]\e[0m $1"
}

print_success() {
    echo -e "\e[1;32m[SUCCESS]\e[0m $1"
}

print_warning() {
    echo -e "\e[1;33m[WARNING]\e[0m $1"
}

print_error() {
    echo -e "\e[1;31m[ERROR]\e[0m $1"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

install_package() {
    local package_name="$1"
    if ! rpm -q "$package_name" >/dev/null; then
        print_info "Installing $package_name..."
        sudo dnf install -y --allowerasing "$package_name"
        if [ $? -ne 0 ]; then
            print_error "Failed to install $package_name. Exiting."
            exit 1
        fi
    else
        print_info "$package_name is already installed."
    fi
}

install_flatpak_package() {
    local package_id="$1"
    local repo="${2:-flathub}" # Default to flathub
    if ! flatpak info "$package_id" >/dev/null 2>&1; then
        print_info "Installing Flatpak package $package_id..."
        flatpak install -y "$repo" "$package_id"
        if [ $? -ne 0 ]; then
            print_warning "Failed to install Flatpak package $package_id. Check Flatpak setup."
        fi
    else
        print_info "Flatpak package $package_id is already installed."
    fi
}

# --- Sanity Checks ---
print_info "Starting Fedora setup script..."

if [[ "$EUID" -eq 0 ]]; then
   print_error "This script should not be run as root. Run it as your normal user."
   exit 1
fi

if ! command_exists dnf; then
    print_error "'dnf' command not found. Is this a Fedora-based system?"
    exit 1
fi

if ! command_exists git; then
    print_warning "'git' command not found. Installing it first."
    sudo dnf install -y git
fi

# --- System Update & Repositories ---
print_info "Updating system packages..."
sudo dnf update -y

print_info "Enabling RPM Fusion repositories (free and non-free)..."
sudo dnf install -y \
  "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
  "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

print_info "Adding Mullvad VPN repository..."
sudo dnf config-manager addrepo --from-repofile=https://repository.mullvad.net/rpm/stable/mullvad.repo

# --- Package Installation (DNF) ---
print_info "Installing core utilities, development tools, and dependencies..."

# Core Utils & System
dnf_packages=(
    stow zsh curl wget unzip zip git gnupg util-linux-user tar
    btop bat eza zoxide tldr thefuck tree
    nmap openvpn network-manager-applet NetworkManager-openvpn-gnome bluez bluez-tools blueman
    pipewire pipewire-alsa pipewire-pulseaudio wireplumber pavucontrol pamixer
    libnotify procps-ng cronie
    libvirt qemu-kvm virt-manager # For VMs
    make automake gcc gcc-c++ cmake clang pkg-config ninja-build glib2-devel libevdev-devel libconfig-devel
    lxpolkit # PolicyKit Authentication Agent
    xdg-utils xdg-desktop-portal xdg-desktop-portal-gtk xdg-user-dirs
    gparted parted # Disk management
    sqlite pandoc xxd
    python3 python3-pip python3-devel
    ffmpeg
    obs-studio # Needs RPM Fusion
    wl-clipboard # Wayland clipboard tool (used by some apps)
    swaybg # Background image viewer
    mullvad-vpn # Needs Mullvad repo or manual install - assuming repo added/manual
    arandr # Screen GUI (X11 mostly, maybe useful)
    wlsunset # Gamma adjustment for Wayland
    chafa # In-terminal image viewer
    neovim vim
    zsh-autosuggestions
    zsh-syntax-highlighting
)

# Hyprland & Wayland Ecosystem
dnf_packages+=(
    hyprland hyprlock hypridle hyprcursor hyprpicker
    waybar
    rofi # Your config uses Rofi
    # tofi # Your config references tofi as well
    SwayNotificationCenter # Notification daemon
    xdg-desktop-portal-hyprland
)

# Terminal Emulators
dnf_packages+=(
    wezterm
    # blackbox-terminal # Check if available in Fedora repos or needs Flatpak/manual build
)

# GUI Apps (some might be preferred as Flatpaks)
dnf_packages+=(
    nautilus
    # vscode # Often installed via MS repo or Flatpak
    # burpsuite # Needs manual download/install
)

# Fonts (System packages for management + specific fonts)
dnf_packages+=(
    fontawesome-fonts google-noto-sans-fonts google-noto-serif-fonts google-noto-mono-fonts
    fira-code-fonts terminus-fonts jetbrains-mono-fonts
    fontconfig freetype freetype-devel # Font management
)

for pkg in "${dnf_packages[@]}"; do
    install_package "$pkg"
done

# Install Code - OSS (Alternative to vscode package, often preferred)
print_info "Adding VS Code (Code - OSS) repository and installing..."
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
dnf check-update
install_package code

# Install QMK CLI via pip
print_info "Installing QMK CLI via pip..."
pip3 install --user qmk
if [ $? -ne 0 ]; then
    print_warning "Failed to install QMK CLI via pip. Check pip setup and internet connection."
    # Decide if this is critical enough to exit
    # print_error "QMK installation failed. Exiting."
    # exit 1
else
    # Add ~/.local/bin to PATH if not already present for the current session AND profile
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        print_info "Adding $HOME/.local/bin to PATH for this session."
        export PATH="$HOME/.local/bin:$PATH"
        # Also attempt to add to .bashrc or .zshrc (idempotently)
        # Note: This assumes Zsh will be the default shell later.
        ZSHRC_PATH="$USER_HOME/.zshrc"
        BASHRC_PATH="$USER_HOME/.bashrc"
        PATH_EXPORT_LINE='export PATH="$HOME/.local/bin:$PATH"'

        grep -qF -- "$PATH_EXPORT_LINE" "$ZSHRC_PATH" || echo "$PATH_EXPORT_LINE" >> "$ZSHRC_PATH"
        grep -qF -- "$PATH_EXPORT_LINE" "$BASHRC_PATH" || echo "$PATH_EXPORT_LINE" >> "$BASHRC_PATH"
        print_info "Added $HOME/.local/bin to PATH in $ZSHRC_PATH and $BASHRC_PATH if not already present."
    fi
    print_success "QMK CLI installed."
fi

# Install Docker (using moby-engine from Fedora repos)
print_info "Installing moby-engine and Docker Compose..."
install_package moby-engine # Docker engine
install_package docker-compose # Docker Compose V2 CLI

# --- Flatpak Setup and Installation ---
print_info "Setting up Flatpak and Flathub repository..."
install_package flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

print_info "Installing Flatpak applications..."
flatpak_packages=(
    org.gnome.Loupe # Image viewer
    org.gnome.Evince # PDF Viewer
    # Add other Flatpak app IDs here if needed
    # com.github.tchx84.Flatseal # Optional: To manage Flatpak permissions
    # com.getpostman.Postman # Example
)

for app_id in "${flatpak_packages[@]}"; do
    install_flatpak_package "$app_id"
done

# --- Font Installation (Nerd Fonts) ---
print_info "Installing Nerd Fonts (FiraCode, Hack, JetBrainsMono, Meslo)..."

NERDFONT_DIR="$USER_HOME/.local/share/fonts"
mkdir -p "$NERDFONT_DIR"

# Define Nerd Fonts to install (add more if needed)
nerd_fonts=("FiraCode" "Hack" "JetBrainsMono" "Meslo")

for font_name in "${nerd_fonts[@]}"; do
    print_info "Checking for existing $font_name Nerd Font..."
    # Check if any files containing the font name already exist in the target dir
    if compgen -G "$NERDFONT_DIR/*${font_name}*" > /dev/null; then
        print_success "$font_name Nerd Font already seems to be installed. Skipping download."
        continue # Skip to the next font
    fi

    print_info "Downloading and installing $font_name Nerd Font..."
    # Construct the download URL (adjust version if needed)
    zip_file="${font_name}.zip"
    download_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/${zip_file}" # Using v3.2.1 as an example
    
    wget -q "$download_url" -O "/tmp/${zip_file}"
    if [ $? -ne 0 ]; then
        print_warning "Failed to download $font_name Nerd Font from $download_url. Skipping."
        continue
    fi
    
    # Create temporary directory for extraction
    temp_font_dir="/tmp/nerd_fonts_${font_name}_extract"
    mkdir -p "$temp_font_dir"
    
    # Extract to temporary directory
    unzip -q -o "/tmp/${zip_file}" -d "$temp_font_dir/"
    if [ $? -ne 0 ]; then
        print_warning "Failed to unzip $font_name Nerd Font. Skipping."
        rm -rf "$temp_font_dir"
        rm -f "/tmp/${zip_file}"
        continue
    fi
    
    # Move only font files to font directory
    print_info "Moving font files to $NERDFONT_DIR..."
    find "$temp_font_dir" -type f \( -name "*.ttf" -o -name "*.otf" \) -exec cp -v {} "$NERDFONT_DIR/" \;
    
    # Clean up
    rm -rf "$temp_font_dir"
    rm -f "/tmp/${zip_file}"
    
    print_success "Installed $font_name Nerd Font."
done

print_info "Updating font cache..."
fc-cache -fv

print_info "Part 1 (Setup, Packages, Fonts) Complete."
print_info "Next steps involve setting up Stow, Zsh, and applying configurations."

# --- Stow Setup ---
print_info "Setting up Stow directory structure..."
mkdir -p "$STOW_DIR"

print_info "Preparing configuration files for Stow..."

# Function to safely copy files
safe_copy() {
    local src="$1"
    local dest_dir="$2"
    if [ -e "$src" ]; then
        mkdir -p "$(dirname "$dest_dir")" # Ensure parent directory exists
        cp -v "$src" "$dest_dir"
        print_success "Copied '$src' to '$dest_dir'"
    else
        print_warning "Source file not found, skipping copy: $src"
    fi
}

# Function to safely copy directory contents
safe_copy_dir() {
    local src_dir="$1"
    local dest_dir="$2"

    if [ -d "$src_dir" ]; then
        print_info "Copying contents of '$src_dir' to '$dest_dir'..."
        mkdir -p "$dest_dir"
        # Use rsync for better handling of files/dirs
        rsync -av --no-owner --no-group "$src_dir/" "$dest_dir/"
        print_success "Copied contents of '$src_dir' to '$dest_dir'"
    else
        print_warning "Source directory not found, skipping copy: $src_dir"
    fi
}

# Hyprland - Correct structure for stow is $STOW_DIR/hypr/.config/hypr/
safe_copy_dir "$DOTFILES_DIR/hypr" "$STOW_DIR/hypr/.config/hypr"

# Waybar
safe_copy_dir "$DOTFILES_DIR/waybar" "$STOW_DIR/waybar/.config/waybar"

# Wezterm
mkdir -p "$STOW_DIR/wezterm/.config/wezterm"
safe_copy "$DOTFILES_DIR/term/wezterm.lua" "$STOW_DIR/wezterm/.config/wezterm/wezterm.lua"

# Zsh (Copy p10k config, .zshrc generated later)
mkdir -p "$STOW_DIR/zsh"
safe_copy "$DOTFILES_DIR/p10k.zsh" "$STOW_DIR/zsh/.p10k.zsh"

# Git (Structure only, .gitconfig generated later)
mkdir -p "$STOW_DIR/git"

# Scripts
mkdir -p "$STOW_DIR/scripts/.local/bin"
if [ -d "$DOTFILES_DIR/scripts" ]; then
    find "$DOTFILES_DIR/scripts" -maxdepth 1 -type f -print0 | while IFS= read -r -d $'\0' script_file; do
        safe_copy "$script_file" "$STOW_DIR/scripts/.local/bin/$(basename "$script_file")"
    done
    print_info "Setting executable permissions for scripts..."
    chmod +x "$STOW_DIR/scripts/.local/bin/"*
else
    print_warning "Original scripts directory not found: $DOTFILES_DIR/scripts"
fi

# Superfile (now its own package)
mkdir -p "$STOW_DIR/superfile/.config/superfile"
safe_copy "$DOTFILES_DIR/tools/superfile/config.toml" "$STOW_DIR/superfile/.config/superfile/config.toml"

# Rofi
mkdir -p "$STOW_DIR/rofi/.config/rofi"

# Btop
mkdir -p "$STOW_DIR/btop/.config/btop"

# Bat
mkdir -p "$STOW_DIR/bat/.config/bat"

# Fonts (User font configuration structure)
mkdir -p "$STOW_DIR/fonts/.config/fontconfig/conf.d"

# Tools (Docker compose etc.) - ONLY create nested tools/tools structure
mkdir -p "$STOW_DIR/tools/tools/linkding"
mkdir -p "$STOW_DIR/tools/tools/stirling_pdf"

safe_copy "$DOTFILES_DIR/tools/linkding/docker-compose.yml" "$STOW_DIR/tools/tools/linkding/docker-compose.yml"
if [ -f "$DOTFILES_DIR/tools/linkding/.env" ]; then
    safe_copy "$DOTFILES_DIR/tools/linkding/.env" "$STOW_DIR/tools/tools/linkding/.env"
fi

safe_copy "$DOTFILES_DIR/tools/stirling_pdf/docker-compose.yml" "$STOW_DIR/tools/tools/stirling_pdf/docker-compose.yml"
if [ -f "$DOTFILES_DIR/tools/stirling_pdf/.env" ]; then
    safe_copy "$DOTFILES_DIR/tools/stirling_pdf/.env" "$STOW_DIR/tools/tools/stirling_pdf/.env"
fi

# Create tools README with usage instructions
cat << EOF > "$STOW_DIR/tools/tools/README.md"
# Tools Directory

This directory contains various tool configurations and Docker Compose setups.

## Available Tools

### Linkding
A bookmark management service. To start:
\`\`\`bash
cd ~/tools/linkding
docker-compose up -d
\`\`\`

### Stirling PDF
A PDF manipulation tool. To start:
\`\`\`bash
cd ~/tools/stirling_pdf
docker-compose up -d
\`\`\`
EOF

# SSH (Copy existing config if present)
mkdir -p "$STOW_DIR/ssh/.ssh"
if [ -f "$DOTFILES_DIR/ssh/config" ]; then
    safe_copy "$DOTFILES_DIR/ssh/config" "$STOW_DIR/ssh/.ssh/config"
else
    # Create an empty config if none exists in source, stow needs a file/dir to link
    touch "$STOW_DIR/ssh/.ssh/config"
fi

print_warning "SSH keys (.ssh/id_*) were NOT copied. Please copy them manually to $USER_HOME/.ssh/ and set permissions (chmod 600 for private keys, 644 for public)."
print_info "Stow directory setup complete."

# --- Generate Config Files ---
print_info "Generating .gitconfig into Stow directory..."
cat << EOF > "$STOW_DIR/git/.gitconfig"
# Generated by setup script from git.nix
[user]
    name = $GIT_USER_NAME
    email = $GIT_USER_EMAIL

[core]
    editor = $EDITOR_CMD
    pager = delta

[pull]
    rebase = true

[interactive]
    diffFilter = delta --color-only

[delta]
    navigate = true
    side-by-side = true
    # dark = true
    # light = true

[merge]
    conflictstyle = diff3

[diff]
    colorMoved = default

# Aliases from git.nix
[alias]
    co = checkout
    br = branch
    ci = commit
    st = status
EOF
print_success "Generated $STOW_DIR/git/.gitconfig"

print_info "Generating .zshrc into Stow directory..."
# Use single quotes around EOF to prevent immediate variable expansion
cat << 'EOF' > "$STOW_DIR/zsh/.zshrc"
# ~/.zshrc: sourced by zsh interactive shells.

# --- Path Setup ---
# Add ~/.local/bin to PATH if it exists and isn't already there
if [[ -d "$HOME/.local/bin" && ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

# Add custom scripts directory from dotfiles source
# Check if the directory exists and the path isn't already added
if [[ -d "$DOTFILES_DIR/scripts" && ":$PATH:" != *":$DOTFILES_DIR/scripts:"* ]]; then
  export PATH="$PATH:$DOTFILES_DIR/scripts"
fi

# Add ~/.cargo/bin for uv and other rust tools
if [[ -d "$HOME/.cargo/bin" && ":$PATH:" != *":$HOME/.cargo/bin:"* ]]; then
  export PATH="$HOME/.cargo/bin:$PATH"
fi

# --- Environment Variables ---
# Set preferred editor
export EDITOR='nano'
export VISUAL='nano'

# XDG Base Directory Specification (Optional but recommended)
# export XDG_CONFIG_HOME="$HOME/.config"
# export XDG_CACHE_HOME="$HOME/.cache"
# export XDG_DATA_HOME="$HOME/.local/share"
# export XDG_STATE_HOME="$HOME/.local/state"

# Zsh history configuration based on sh.nix
export HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history" # Store history in XDG standard location
export HISTSIZE=1000  # Max history lines in memory
export SAVEHIST=1000  # Max history lines saved to file
setopt share_history # Share history between terminals immediately
setopt hist_expire_dups_first # Expire duplicate entries first
setopt hist_ignore_dups # Do not record an event if it is just a duplicate of the previous event
setopt hist_ignore_all_dups # Delete old recorded event if a new identical event is added
setopt hist_find_no_dups # When searching history, do not display duplicates of a line previously found
setopt hist_save_no_dups # Do not write duplicate consecutive commands to the history file
setopt hist_verify # Don't execute history expansion commands immediately

# Ensure the history directory exists
mkdir -p "$(dirname "$HISTFILE")"

# Bat theme from sh.nix
export BAT_THEME="base16"

# Set default browser if needed
# export BROWSER='firefox'

# --- Oh My Zsh ---
# Check if ZSH is defined, otherwise default to standard location
export ZSH="${ZSH:-$HOME/.oh-my-zsh}"

# Load Oh My Zsh configuration.
# NOTE: Consider managing OMZ plugins via a plugin manager instead for more flexibility.
# OMZ Plugins from sh.nix: git, thefuck
ZSH_THEME="robbyrussell" # Base theme, P10k will override if loaded later
plugins=(git thefuck eza zoxide)

# Load OMZ - Check if it exists first
if [ -d "$ZSH" ]; then
  source "$ZSH/oh-my-zsh.sh"
else
  echo "[Warning] Oh My Zsh not found at $ZSH. Run install script or manually install."
fi

# --- Plugin Manager (Optional - e.g., zinit, antigen, zgenom) ---
# If you prefer a plugin manager, configure it here instead of OMZ plugins array
# Example using manual plugin sourcing (less robust than a manager):
# ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
# ZSH_PLUGINS_DIR="$ZSH_CUSTOM/plugins"
# mkdir -p "$ZSH_PLUGINS_DIR"

# --- Zsh Plugins (Autosuggestions, Syntax Highlighting) ---
# Source plugins from Fedora package locations if they exist.
# Correct paths based on `rpm -ql` output.

# Zsh Autosuggestions
ZSH_AUTOSUGGEST_PATH="/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
if [ -f "$ZSH_AUTOSUGGEST_PATH" ]; then
  source "$ZSH_AUTOSUGGEST_PATH"
else
  echo "[Warning] zsh-autosuggestions not found at $ZSH_AUTOSUGGEST_PATH"
fi

# Zsh Syntax Highlighting
ZSH_SYNTAX_HIGHLIGHT_PATH="/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
if [ -f "$ZSH_SYNTAX_HIGHLIGHT_PATH" ]; then
  source "$ZSH_SYNTAX_HIGHLIGHT_PATH"
else
  echo "[Warning] zsh-syntax-highlighting not found at $ZSH_SYNTAX_HIGHLIGHT_PATH"
fi

# --- Powerlevel10k Theme ---
# Source P10k config (which sources the theme) if it exists
# Assumes .p10k.zsh is in the same directory as .zshrc (linked by stow)
ZSH_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh" # Or simply $HOME if not stowing to .config
P10K_CONFIG="$HOME/.p10k.zsh" # Default location p10k expects
if [ -f "$P10K_CONFIG" ]; then
  # Check if p10k function exists (means theme might be loaded)
  # This tries to source the config file which initializes P10k.
  [[ ! -f "$P10K_CONFIG" ]] || source "$P10K_CONFIG"
else
 echo "[Warning] Powerlevel10k config not found at $P10K_CONFIG."
fi

# --- Aliases (from sh.nix, excluding NixOS-specific) ---
alias python='python3'
alias py='python3'
alias pip='uv pip' # Changed from 'python3 -m pip'
alias venv='uv venv .venv && source .venv/bin/activate' # Changed to uv venv
alias activate='source .venv/bin/activate'
alias getip='curl -4 icanhazip.com' # Force IPv4 for wider compatibility
alias vi='nvim'
alias vim='nvim'
alias cat='bat -p'
alias ls='eza --icons --color=always --group-directories-first' # Added common eza flags
alias ll='eza -l --icons --color=always --group-directories-first' # Long format
alias lsa='eza -la --icons --color=always --group-directories-first' # Long format + all
alias sl='ls' # Typo correction
alias tree='eza --icons --tree'
alias chmox='chmod +x'
alias fix_python='echo "fix_python alias may need review/adjustment for Fedora"' # Placeholder
alias spf='superfile'
alias exegol='echo "exegol alias requires manual setup of the Exegol container/script"' # Placeholder
# Docker aliases
alias ubuntu_docker='sudo docker run --rm -it ubuntu bash'
alias alpine='sudo docker run --rm -it -v "$HOME/VMs/alpine_docker/alpine_data:/mydata" alpine' # Adjusted mount
# C compilation aliases
alias cc='gcc -Wall -Werror -Wextra'
alias comp='gcc -Wall -Werror -Wextra *.c'
alias runc='comp && ./a.out'
# Custom utility aliases
alias trash='echo "Emptying trash directory in /tmp/trash-${USER}..." && command rm -rf /tmp/trash-${USER}/* && echo "Trash emptied."'
alias codeC='code *.c' # Requires 'code' command (VS Code)
alias open_resume='docker run --rm -p 3000:3000 open-resume' # Requires manual setup of open-resume image

# --- Functions (from sh.nix, excluding NixOS-specific) ---
# cd with zoxide and ls
cd() {
  # Check if argument is provided and if zoxide exists
  if [[ -n "$1" && -x "$(command -v zoxide)" ]]; then
    # Use zoxide cd, then list if successful
    z "$@" && ls
  else
    # Fallback to standard builtin cd if no arg or zoxide missing
    # Only run ls if cd was successful
    command cd "$@" && ls
  fi
}

# Git save function
save() {
    local commit_message
    if [ -z "$1" ]; then
        commit_message="Save changes via save function" # More descriptive default
    else
        commit_message="$1"
    fi
    echo "Running: git add . && git commit -m "$commit_message" && git push"
    git add . && git commit -m "$commit_message" && git push
}

# Safer rm (moves to a temporary trash directory)
# Note: Files in /tmp are volatile and will be lost on reboot
rm() {
    local trash_dir="/tmp/trash-${USER}" # User-specific trash
    mkdir -p "$trash_dir"
    if [ "$#" -eq 0 ]; then
        echo "Usage: rm <file1> [file2]..." >&2
        return 1
    fi
    echo -e "\033[1;33mMoving to $trash_dir:\033[0m $@"
    # Use mv with --target-directory for robustness
    command mv -v --target-directory="$trash_dir" -- "$@"
    if [ $? -eq 0 ]; then
         echo -e "\033[1;32mSuccessfully moved to trash.\033[0m"
    else
         echo -e "\033[1;31mError moving files to trash.\033[0m" >&2
         return 1
    fi
}

# Create a new directory and cd into it
nd(){ mkdir -p "$1" && cd "$1"; } # Added quotes and -p

# Find processes
findps(){ ps -aux | grep --color=auto "$1"; }

# Get Local IP address (improved version)
localIP(){
    ip -4 addr show | grep -oP '(?<=inet\\s)\\d+(\\.\\d+){3}' | grep -v '127.0.0.1' | head -n 1 || echo \"No local IPv4 found\"
}

# Creates a python HTTP server and displays its IP address
shareLocal() {
    local ip_addr
    ip_addr=$(ip -4 addr show | grep -oP '(?<=inet\\s)\\d+(\\.\\d+){3}' | grep -v '127.0.0.1' | head -n 1)
    if [ -z "$ip_addr" ]; then
        echo \"Could not determine local IP address.\" >&2
        return 1
    fi
    local port=8000
    echo -e \"\\nServing current directory ($PWD) on : http://$ip_addr:$port\\n\\n\"
    # Check if python3 is available
    if command -v python3 >/dev/null; then
        python3 -m http.server "$port"
    elif command -v python >/dev/null; then
        python -m SimpleHTTPServer "$port" # Fallback for older systems
    else
        echo \"Python not found. Cannot start HTTP server.\" >&2
        return 1
    fi
}

# SSH mode function (relies on the script being in PATH)
ssh_mode() {
  if command -v ssh_mode.sh >/dev/null; then
    ssh_mode.sh "$@"
  else
    echo \"Error: ssh_mode.sh script not found in PATH.\" >&2
  fi
}

# Pretty print CSV
csv() {
  if [ -z "$1" ] || [ ! -f "$1" ]; then
    echo \"Usage: csv <filename.csv>\" >&2
    return 1
  fi
  column -s, -t < "$1" | less -#2 -N -S
}

# Docker services management function
docker-services() {
  # Color definitions
  local GREEN='\033[0;32m'
  local YELLOW='\033[0;33m'
  local RED='\033[0;31m'
  local BLUE='\033[0;34m'
  local NC='\033[0m' # No Color
  
  # Display usage information
  usage() {
    echo -e "${BLUE}Docker Services Helper${NC}"
    echo "Manages Docker Compose services in the ~/tools directory"
    echo
    echo "Usage: docker-services [command] [service]"
    echo
    echo "Commands:"
    echo "  list          - List all available services"
    echo "  start [svc]   - Start a specific service or all services"
    echo "  stop [svc]    - Stop a specific service or all services"
    echo "  restart [svc] - Restart a specific service or all services"
    echo "  status        - Show status of all services"
    echo "  logs [svc]    - Show logs for a specific service"
    echo
    echo "Services:"
    for dir in ~/tools/*/; do
      if [ -f "${dir}docker-compose.yml" ]; then
        svc=$(basename "$dir")
        echo "  $svc"
      fi
    done
  }
  
  # Check if Docker is running
  check_docker() {
    if ! docker info &>/dev/null; then
      echo -e "${RED}Error: Docker is not running or you don't have permission.${NC}"
      echo "Try starting Docker with: sudo systemctl start docker"
      echo "Or add yourself to the docker group and log out/in."
      return 1
    fi
    return 0
  }
  
  # List available services
  list_services() {
    echo -e "${BLUE}Available services:${NC}"
    local found=false
    for dir in ~/tools/*/; do
      if [ -f "${dir}docker-compose.yml" ]; then
        svc=$(basename "$dir")
        echo -e "- ${GREEN}$svc${NC}"
        found=true
      fi
    done
    if [ "$found" = false ]; then
      echo -e "${YELLOW}No Docker Compose services found in ~/tools/${NC}"
    fi
  }
  
  # Start services
  start_service() {
    check_docker || return 1
    
    if [ -z "$1" ]; then
      echo -e "${YELLOW}Starting all services...${NC}"
      for dir in ~/tools/*/; do
        if [ -f "${dir}docker-compose.yml" ]; then
          svc=$(basename "$dir")
          echo -e "${BLUE}Starting $svc...${NC}"
          (cd "$dir" && docker-compose up -d)
        fi
      done
    else
      if [ -d ~/tools/"$1" ] && [ -f ~/tools/"$1"/docker-compose.yml ]; then
        echo -e "${BLUE}Starting $1...${NC}"
        (cd ~/tools/"$1" && docker-compose up -d)
      else
        echo -e "${RED}Service $1 not found or missing docker-compose.yml${NC}"
        return 1
      fi
    fi
  }
  
  # Stop services
  stop_service() {
    check_docker || return 1
    
    if [ -z "$1" ]; then
      echo -e "${YELLOW}Stopping all services...${NC}"
      for dir in ~/tools/*/; do
        if [ -f "${dir}docker-compose.yml" ]; then
          svc=$(basename "$dir")
          echo -e "${BLUE}Stopping $svc...${NC}"
          (cd "$dir" && docker-compose down)
        fi
      done
    else
      if [ -d ~/tools/"$1" ] && [ -f ~/tools/"$1"/docker-compose.yml ]; then
        echo -e "${BLUE}Stopping $1...${NC}"
        (cd ~/tools/"$1" && docker-compose down)
      else
        echo -e "${RED}Service $1 not found or missing docker-compose.yml${NC}"
        return 1
      fi
    fi
  }
  
  # Restart a service
  restart_service() {
    check_docker || return 1
    
    if [ -z "$1" ]; then
      echo -e "${YELLOW}Restarting all services...${NC}"
      for dir in ~/tools/*/; do
        if [ -f "${dir}docker-compose.yml" ]; then
          svc=$(basename "$dir")
          echo -e "${BLUE}Restarting $svc...${NC}"
          (cd "$dir" && docker-compose restart)
        fi
      done
    else
      if [ -d ~/tools/"$1" ] && [ -f ~/tools/"$1"/docker-compose.yml ]; then
        echo -e "${BLUE}Restarting $1...${NC}"
        (cd ~/tools/"$1" && docker-compose restart)
      else
        echo -e "${RED}Service $1 not found or missing docker-compose.yml${NC}"
        return 1
      fi
    fi
  }
  
  # Show service status
  show_status() {
    check_docker || return 1
    
    local found=false
    echo -e "${BLUE}Services status:${NC}"
    for dir in ~/tools/*/; do
      if [ -f "${dir}docker-compose.yml" ]; then
        svc=$(basename "$dir")
        echo -e "${GREEN}$svc:${NC}"
        
        # Get container IDs for this service
        local containers
        containers=$(cd "$dir" && docker-compose ps -q 2>/dev/null)
        
        if [ -z "$containers" ]; then
          echo -e "  ${YELLOW}Not running${NC}"
        else
          docker ps --format "  {{.Status}}\t{{.Ports}}" --filter "id=${containers}"
          found=true
        fi
        echo
      fi
    done
    
    if [ "$found" = false ]; then
      echo -e "${YELLOW}No active services found${NC}"
    fi
  }
  
  # Show logs for a service
  show_logs() {
    check_docker || return 1
    
    if [ -z "$1" ]; then
      echo -e "${RED}Error: Please specify a service to show logs for${NC}"
      return 1
    fi
    
    if [ -d ~/tools/"$1" ] && [ -f ~/tools/"$1"/docker-compose.yml ]; then
      echo -e "${BLUE}Showing logs for $1...${NC}"
      (cd ~/tools/"$1" && docker-compose logs --tail=100 -f)
    else
      echo -e "${RED}Service $1 not found or missing docker-compose.yml${NC}"
      return 1
    fi
  }
  
  # Handle arguments
  if [ $# -eq 0 ]; then
    usage
    return 0
  fi
  
  case "$1" in
    list)
      list_services
      ;;
    start)
      start_service "$2"
      ;;
    stop)
      stop_service "$2"
      ;;
    status)
      show_status
      ;;
    logs)
      show_logs "$2"
      ;;
    restart)
      restart_service "$2"
      ;;
    *)
      usage
      return 1
      ;;
  esac
}

# --- Tool Initializations ---

# Initialize Zoxide
if command -v zoxide >/dev/null; then
  eval "$(zoxide init zsh)"
else
  echo "[Warning] zoxide not found, 'cd' function will use standard builtin."
fi

# --- Final Setup ---
# Run pfetch if available
if command -v pfetch >/dev/null; then
  # pfetch # Uncomment if you want pfetch to run on every shell start
elif command -v neofetch >/dev/null; then
  # neofetch # Uncomment if you prefer neofetch
fi

# Set correct permissions for completions (if needed, OMZ usually handles this)
# compaudit | xargs chmod g-w

# Source local/custom zsh config if it exists
if [ -f "$HOME/.zshrc.local" ]; then
  source "$HOME/.zshrc.local"
fi

# unset ZSH_CUSTOM # Optional cleanup

echo "Zsh setup complete." # Optional message
EOF

# --- Apply editor value in the generated zshrc ---
sed -i "s/export EDITOR='nano'/export EDITOR='$EDITOR_CMD'/g" "$STOW_DIR/zsh/.zshrc"
sed -i "s/export VISUAL='nano'/export VISUAL='$EDITOR_CMD'/g" "$STOW_DIR/zsh/.zshrc"

print_success "Generated $STOW_DIR/zsh/.zshrc with editor set to $EDITOR_CMD"

# --- Stow Linking ---
print_info "Stowing configuration files from $STOW_DIR to $USER_HOME..."
if [ -d "$STOW_DIR" ]; then
    # Cleanup any problematic files before stowing
    print_info "Cleaning up potential conflicts before stowing..."
    
    # Remove the problematic superfile config if it exists and is not a symlink
    SUPERFILE_CONFIG="$USER_HOME/.config/superfile/config.toml"
    if [ -f "$SUPERFILE_CONFIG" ] && [ ! -L "$SUPERFILE_CONFIG" ]; then
        print_warning "Removing existing superfile config file: $SUPERFILE_CONFIG"
        rm -f "$SUPERFILE_CONFIG"
    fi
    
    # Make sure we don't have duplicate config paths in tools package
    if [ -d "$STOW_DIR/tools/.config" ]; then
        print_warning "Removing conflicting config directory in tools package"
        rm -rf "$STOW_DIR/tools/.config"
    fi
    
    # Remove any top-level linkding and stirling_pdf directories in the tools package
    if [ -e "$STOW_DIR/tools/linkding" ] && [ ! -L "$STOW_DIR/tools/linkding" ]; then
        print_warning "Removing top-level linkding directory in tools package"
        rm -rf "$STOW_DIR/tools/linkding"
    fi
    
    if [ -e "$STOW_DIR/tools/stirling_pdf" ] && [ ! -L "$STOW_DIR/tools/stirling_pdf" ]; then
        print_warning "Removing top-level stirling_pdf directory in tools package"
        rm -rf "$STOW_DIR/tools/stirling_pdf"
    fi
    
    # Check for and remove linkding/stirling_pdf in home if they exist and are not symlinks
    if [ -d "$USER_HOME/linkding" ] && [ ! -L "$USER_HOME/linkding" ]; then
        print_warning "Removing existing linkding directory in home: $USER_HOME/linkding" 
        rm -rf "$USER_HOME/linkding"
    fi
    
    if [ -d "$USER_HOME/stirling_pdf" ] && [ ! -L "$USER_HOME/stirling_pdf" ]; then
        print_warning "Removing existing stirling_pdf directory in home: $USER_HOME/stirling_pdf"
        rm -rf "$USER_HOME/stirling_pdf"
    fi
    
    # Change to the directory containing the packages to be stowed
    cd "$STOW_DIR" || { print_error "Could not change to STOW_DIR: $STOW_DIR"; exit 1; }

    # Try stowing all packages
    print_info "Stowing packages..."
    if stow -v -R -t "$USER_HOME" *; then
        print_success "Successfully stowed configuration files."
    else
        print_error "Stow command failed. Trying with --adopt option..."
        
        # Try using --adopt which can help with conflicts
        if stow -v -R --adopt -t "$USER_HOME" *; then
            print_success "Successfully stowed configurations using --adopt option."
            print_warning "Existing files were adopted into the stow directory. Review changes if needed."
        else
            print_error "Stow with --adopt also failed. Trying individual packages..."
            
            # Try stowing packages one by one to identify problematic ones
            for pkg in */; do
                pkg=${pkg%/} # Remove trailing slash
                print_info "Stowing package: $pkg"
                
                if stow -v -R -t "$USER_HOME" "$pkg"; then
                    print_success "Successfully stowed $pkg."
                else
                    print_warning "Failed to stow $pkg. Skipping."
                fi
            done
        fi
    fi

    # Change back to the original directory
    cd - > /dev/null || exit

    # Post-stow cleanup - remove any lingering direct symlinks in home directory
    if [ -L "$USER_HOME/linkding" ]; then
        print_warning "Removing unwanted linkding symlink in home directory"
        rm -f "$USER_HOME/linkding"
    fi
    
    if [ -L "$USER_HOME/stirling_pdf" ]; then
        print_warning "Removing unwanted stirling_pdf symlink in home directory"
        rm -f "$USER_HOME/stirling_pdf"
    fi
 else
    print_error "Stow directory not found: $STOW_DIR. Cannot stow files."
 fi

print_info "Stow linking process complete."

# --- Install uv (Python package manager) ---
print_info "Installing uv (faster pip/venv)..."
if ! command -v uv &> /dev/null; then
    if command -v curl &> /dev/null; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
        if [ $? -ne 0 ]; then
            print_warning "uv installation via script failed. Check curl output."
        else
            # Add ~/.cargo/bin to PATH for the current script session if not already present
            if [[ ":$PATH:" != *":$HOME/.cargo/bin:"* ]]; then
                 print_info "Adding $HOME/.cargo/bin to PATH for this session."
                 export PATH="$HOME/.cargo/bin:$PATH"
            fi
            # Check if uv is now in PATH
            if command -v uv &> /dev/null; then
                 print_success "uv installed successfully."
                 print_info "Make sure to add $HOME/.cargo/bin to your PATH permanently."
            else
                 print_warning "uv installed but not found in PATH immediately. Check $HOME/.cargo/bin."
            fi
        fi
    else
        print_error "curl not found. Cannot install uv automatically."
    fi
else
    print_info "uv is already installed."
fi

# --- Change Default Shell to Zsh ---
if command -v zsh >/dev/null; then
    ZSH_PATH=$(command -v zsh)
    CURRENT_SHELL=$(getent passwd "$USERNAME" | cut -d: -f7)
    if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
        print_info "Changing default shell to Zsh for user $USERNAME..."
        # Check if ZSH_PATH is in /etc/shells
        if grep -Fxq "$ZSH_PATH" /etc/shells; then
             sudo chsh -s "$ZSH_PATH" "$USERNAME"
             if [ $? -eq 0 ]; then
                 print_success "Default shell changed to Zsh. Please log out and log back in for the change to take effect."
             else
                 print_error "Failed to change shell using chsh."
             fi
        else
             print_warning "Zsh path ($ZSH_PATH) not found in /etc/shells."
             print_info "Adding Zsh to /etc/shells..."
             echo "$ZSH_PATH" | sudo tee -a /etc/shells > /dev/null
             if grep -Fxq "$ZSH_PATH" /etc/shells; then
                 print_success "Added Zsh to /etc/shells. Attempting to change shell again..."
                 sudo chsh -s "$ZSH_PATH" "$USERNAME"
                 if [ $? -eq 0 ]; then
                     print_success "Default shell changed to Zsh. Please log out and log back in for the change to take effect."
                 else
                     print_error "Failed to change shell using chsh after adding to /etc/shells."
                 fi
             else
                 print_error "Failed to add Zsh to /etc/shells. Cannot change default shell automatically."
             fi
        fi
    else
        print_info "Default shell is already Zsh."
    fi
else
    print_warning "Zsh command not found. Cannot change default shell."
fi

# --- Service Management ---

# Enable and start Docker service
print_info "Enabling and starting Docker service..."
if command -v systemctl >/dev/null && command -v docker >/dev/null; then
    sudo systemctl enable docker
    sudo systemctl start docker
    # Add user to docker group (changes require logout/login)
    if getent group docker > /dev/null; then
        print_info "Adding user $USERNAME to the 'docker' group..."
        sudo usermod -aG docker "$USERNAME"
        if [ $? -ne 0 ]; then
            print_warning "Failed to add user $USERNAME to docker group. Docker commands might require sudo."
        else
            print_success "User $USERNAME added to docker group. Please log out and log back in for this change to take effect."
            print_warning "Until you log out and back in, you'll need to use 'sudo' with Docker commands."
        fi
    else
        print_warning "'docker' group not found. Skipping adding user."
    fi
    
    # Create tools directory in home if it doesn't exist yet (will be linked by stow later)
    if [ ! -d "$USER_HOME/tools" ]; then
        print_info "Creating tools directory in your home folder..."
        mkdir -p "$USER_HOME/tools"
    fi
    
    # Setup Docker services helper script
    print_info "Creating Docker services helper script..."
    mkdir -p "$STOW_DIR/scripts/.local/bin"
    cat << 'EOF' > "$STOW_DIR/scripts/.local/bin/docker-services"
#!/usr/bin/env bash

# Docker Services Helper Script
# Manages docker-compose services in the ~/tools directory

# Color definitions
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Display usage information
usage() {
    echo -e "${BLUE}Docker Services Helper${NC}"
    echo "Manages Docker Compose services in the ~/tools directory"
    echo
    echo "Usage: $(basename "$0") [command] [service]"
    echo
    echo "Commands:"
    echo "  list          - List all available services"
    echo "  start [svc]   - Start a specific service or all services"
    echo "  stop [svc]    - Stop a specific service or all services"
    echo "  restart [svc] - Restart a specific service or all services"
    echo "  status        - Show status of all services"
    echo "  logs [svc]    - Show logs for a specific service"
    echo
    echo "Services:"
    for dir in ~/tools/*/; do
        if [ -f "${dir}docker-compose.yml" ]; then
            svc=$(basename "$dir")
            echo "  $svc"
        fi
    done
}

# Check if Docker is running
check_docker() {
    if ! docker info &>/dev/null; then
        echo -e "${RED}Error: Docker is not running or you don't have permission.${NC}"
        echo "Try starting Docker with: sudo systemctl start docker"
        echo "Or add yourself to the docker group and log out/in."
        return 1
    fi
    return 0
}

# List available services
list_services() {
    echo -e "${BLUE}Available services:${NC}"
    local found=false
    for dir in ~/tools/*/; do
        if [ -f "${dir}docker-compose.yml" ]; then
            svc=$(basename "$dir")
            echo -e "- ${GREEN}$svc${NC}"
            found=true
        fi
    done
    if [ "$found" = false ]; then
        echo -e "${YELLOW}No Docker Compose services found in ~/tools/${NC}"
    fi
}

# Start services
start_service() {
    check_docker || return 1
    
    if [ -z "$1" ]; then
        echo -e "${YELLOW}Starting all services...${NC}"
        for dir in ~/tools/*/; do
            if [ -f "${dir}docker-compose.yml" ]; then
                svc=$(basename "$dir")
                echo -e "${BLUE}Starting $svc...${NC}"
                (cd "$dir" && docker-compose up -d)
            fi
        done
    else
        if [ -d ~/tools/"$1" ] && [ -f ~/tools/"$1"/docker-compose.yml ]; then
            echo -e "${BLUE}Starting $1...${NC}"
            (cd ~/tools/"$1" && docker-compose up -d)
        else
            echo -e "${RED}Service $1 not found or missing docker-compose.yml${NC}"
            return 1
        fi
    fi
}

# Stop services
stop_service() {
    check_docker || return 1
    
    if [ -z "$1" ]; then
        echo -e "${YELLOW}Stopping all services...${NC}"
        for dir in ~/tools/*/; do
            if [ -f "${dir}docker-compose.yml" ]; then
                svc=$(basename "$dir")
                echo -e "${BLUE}Stopping $svc...${NC}"
                (cd "$dir" && docker-compose down)
            fi
        done
    else
        if [ -d ~/tools/"$1" ] && [ -f ~/tools/"$1"/docker-compose.yml ]; then
            echo -e "${BLUE}Stopping $1...${NC}"
            (cd ~/tools/"$1" && docker-compose down)
        else
            echo -e "${RED}Service $1 not found or missing docker-compose.yml${NC}"
            return 1
        fi
    fi
}

# Show service status
show_status() {
    check_docker || return 1
    
    local found=false
    echo -e "${BLUE}Services status:${NC}"
    for dir in ~/tools/*/; do
        if [ -f "${dir}docker-compose.yml" ]; then
            svc=$(basename "$dir")
            echo -e "${GREEN}$svc:${NC}"
            
            # Get container IDs for this service
            local containers
            containers=$(cd "$dir" && docker-compose ps -q 2>/dev/null)
            
            if [ -z "$containers" ]; then
                echo -e "  ${YELLOW}Not running${NC}"
            else
                docker ps --format "  {{.Status}}\t{{.Ports}}" --filter "id=${containers}"
                found=true
            fi
            echo
        fi
    done
    
    if [ "$found" = false ]; then
        echo -e "${YELLOW}No active services found${NC}"
    fi
}

# Show logs for a service
show_logs() {
    check_docker || return 1
    
    if [ -z "$1" ]; then
        echo -e "${RED}Error: Please specify a service to show logs for${NC}"
        return 1
    fi
    
    if [ -d ~/tools/"$1" ] && [ -f ~/tools/"$1"/docker-compose.yml ]; then
        echo -e "${BLUE}Showing logs for $1...${NC}"
        (cd ~/tools/"$1" && docker-compose logs --tail=100 -f)
    else
        echo -e "${RED}Service $1 not found or missing docker-compose.yml${NC}"
        return 1
    fi
}

# Restart a service
restart_service() {
    check_docker || return 1
    
    if [ -z "$1" ]; then
        echo -e "${YELLOW}Restarting all services...${NC}"
        for dir in ~/tools/*/; do
            if [ -f "${dir}docker-compose.yml" ]; then
                svc=$(basename "$dir")
                echo -e "${BLUE}Restarting $svc...${NC}"
                (cd "$dir" && docker-compose restart)
            fi
        done
    else
        if [ -d ~/tools/"$1" ] && [ -f ~/tools/"$1"/docker-compose.yml ]; then
            echo -e "${BLUE}Restarting $1...${NC}"
            (cd ~/tools/"$1" && docker-compose restart)
        else
            echo -e "${RED}Service $1 not found or missing docker-compose.yml${NC}"
            return 1
        fi
    fi
}

# Main execution
if [ $# -eq 0 ]; then
    usage
    exit 0
fi

case "$1" in
    list)
        list_services
        ;;
    start)
        start_service "$2"
        ;;
    stop)
        stop_service "$2"
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "$2"
        ;;
    restart)
        restart_service "$2"
        ;;
    *)
        usage
        exit 1
        ;;
esac
EOF

    # Make the script executable
    chmod +x "$STOW_DIR/scripts/.local/bin/docker-services"
    print_success "Docker services helper script created at '$STOW_DIR/scripts/.local/bin/docker-services'"
    print_info "After installation, you can use 'docker-services' to manage your Docker services."
    
    print_success "Docker service enabled and started."
else
    print_warning "Docker or systemctl not found. Skipping Docker service configuration."
fi

# Enable and start Libvirt service (if virtualization packages were installed)
if command -v systemctl >/dev/null && dnf list installed libvirt-daemon &>/dev/null; then
    print_info "Configuring Libvirt service..."
    sudo systemctl enable libvirtd
    sudo systemctl start libvirtd
    # Add user to libvirt group (requires logout/login)
     if getent group libvirt > /dev/null; then
        print_info "Adding user $USERNAME to the 'libvirt' group..."
        sudo usermod -aG libvirt "$USERNAME"
        print_success "User $USERNAME added to the libvirt group. You need to log out and back in for this change to take effect."
    else
        print_warning "libvirt group not found. Skipping adding user to group."
    fi
    print_success "Libvirt service enabled and started."
else
    print_info "Libvirt not installed or systemctl not found. Skipping Libvirt service configuration."
fi

# --- Final Instructions ---
print_success "-------------------------------------------------"
print_success "      Fedora Setup Script Completed!             "
print_success "-------------------------------------------------"
print_info "Summary of actions:"
print_info "- System updated and repositories configured."
print_info "- Core packages, development tools, GUI apps, and Flatpaks installed."
print_info "- Nerd Fonts installed."
print_info "- Stow directory populated with configurations."
print_info "- .gitconfig and .zshrc generated."
print_info "- Configurations linked using Stow."
print_info "- Default shell likely changed to Zsh (logout/login required)."
print_info "- Docker & Libvirt services configured (if installed, logout/login may be needed for group changes).\n"

print_warning "Important Next Steps:"
print_warning "1. Review script output for any warnings or errors."
print_warning "2. Manually copy your SSH keys (~/.ssh/id_*) to $USER_HOME/.ssh/ and set permissions (chmod 600 private, 644 public)."
print_warning "3. Log out and log back in for all changes (shell, groups) to take full effect."
print_warning "4. Launch Zsh. Powerlevel10k configuration wizard might run if needed."
print_warning "5. Verify your applications and configurations are working as expected."
print_warning "6. Consider rebooting to ensure all services and drivers are loaded correctly."

print_info "Docker Services Management:"
print_info "- The script has added a 'docker-services' function to your Zsh configuration."
print_info "- This allows you to easily manage the Docker Compose services in your ~/tools directory."
print_info "- Usage examples:"
print_info "  • docker-services list    - List available services"
print_info "  • docker-services start linkding - Start the linkding service"
print_info "  • docker-services stop    - Stop all services"
print_info "  • docker-services status  - Show status of all services"
print_info "  • docker-services logs stirling_pdf - Show logs for stirling_pdf"
print_info "- These tools will be available after logging out and back in or sourcing your ~/.zshrc"

print_success "Fedora setup script truly completed!"
exit 0