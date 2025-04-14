#!/usr/bin/env bash

# Fedora Setup Script for Mathieu's NixOS Config Replication
# Version: 1.0

# --- Configuration ---
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STOW_DIR="$USER_HOME/.files" # Changed from $DOTFILES_DIR/stow
USER_HOME="$HOME"
USERNAME="$(whoami)"

# Ensure the permanent Stow directory exists
mkdir -p "$STOW_DIR"

# --- Helper Functions ---

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
        sudo dnf install -y "$package_name"
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

print_info "Adding Docker CE repository..."
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

# --- Package Installation (DNF) ---
print_info "Installing core utilities, development tools, and dependencies..."

# Core Utils & System
dnf_packages=(
    stow zsh curl wget unzip zip git gnupg util-linux-user tar
    btop bat eza fzf zoxide tldr thefuck tree
    nmap openvpn network-manager-applet NetworkManager-openvpn-gnome bluez bluez-tools blueman
    pipewire pipewire-alsa pipewire-pulseaudio wireplumber pavucontrol pamixer
    libnotify procps-ng cronie
    libvirt qemu-kvm virt-manager # For VMs
    make automake gcc gcc-c++ cmake clang pkg-config ninja-build glib2-devel libevdev-devel libconfig-devel
    polkit-gnome # PolicyKit Authentication Agent
    xdg-utils xdg-desktop-portal xdg-desktop-portal-gtk xdg-user-dirs
    gparted parted # Disk management
    sqlite pandoc xxd
    python3 python3-pip python3-devel python3-venv
    ffmpeg
    obs-studio # Needs RPM Fusion
    wl-clipboard # Wayland clipboard tool (used by some apps)
    swaybg # Background image viewer
    qmk # Keyboard firmware tool
    mullvad-vpn # Needs Mullvad repo or manual install - assuming repo added/manual
    arandr # Screen GUI (X11 mostly, maybe useful)
    wlsunset # Gamma adjustment for Wayland
    chafa # In-terminal image viewer
    neovim vim
)

# Hyprland & Wayland Ecosystem
dnf_packages+=(
    hyprland hyprlock hypridle hyprcursor hyprpicker
    waybar
    rofi # Your config uses Rofi
    # tofi # Your config references tofi as well
    swaynotificationcenter # Notification daemon
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

# Install Docker
print_info "Installing Docker CE, containerd, and Docker Compose..."
install_package docker-ce
install_package docker-ce-cli
install_package containerd.io
install_package docker-buildx-plugin
install_package docker-compose-plugin

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
    print_info "Downloading and installing $font_name Nerd Font..."
    # Construct the download URL (adjust version if needed)
    zip_file="${font_name}.zip"
    download_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/${zip_file}" # Using v3.2.1 as an example
    
    wget -q "$download_url" -O "/tmp/${zip_file}"
    if [ $? -ne 0 ]; then
        print_warning "Failed to download $font_name Nerd Font from $download_url. Skipping."
        continue
    fi
    
    unzip -q -o "/tmp/${zip_file}" -d "$NERDFONT_DIR/" # Extract directly into font dir
    if [ $? -ne 0 ]; then
        print_warning "Failed to unzip $font_name Nerd Font. Skipping."
    else
        print_success "Installed $font_name Nerd Font."
    fi
    rm -f "/tmp/${zip_file}"
done

print_info "Updating font cache..."
fc-cache -fv

print_info "Part 1 (Setup, Packages, Fonts) Complete."
print_info "Next steps involve setting up Stow, Zsh, and applying configurations."

# --- Stow Setup ---
print_info "Setting up Stow directory structure..."
mkdir -p "$STOW_DIR"

# Define stow packages based on observed config files and directories
# Added 'tools' for docker-compose files, 'bat'/'btop'/'rofi'/'fonts' for potential future configs
STOW_PACKAGES=("hypr" "waybar" "wezterm" "zsh" "git" "scripts" "ssh" "rofi" "bat" "fonts" "tools")

print_info "Copying configuration files to $STOW_DIR..."

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

# Function to safely copy directory contents (use with caution)
safe_copy_dir() {
    local src_dir="$1"
    local dest_stow_subpath="$2" # e.g., hypr/.config/hypr
    local target_dir="$STOW_DIR/$dest_stow_subpath"

    if [ -d "$src_dir" ]; then
        print_info "Copying contents of '$src_dir' to '$target_dir'..."
        mkdir -p "$target_dir"
        # Use rsync for better handling of files/dirs
        rsync -av --no-owner --no-group "$src_dir/" "$target_dir/"
        print_success "Copied contents of '$src_dir' to '$target_dir'"
    else
        print_warning "Source directory not found, skipping copy: $src_dir"
    fi
}


# Hyprland
safe_copy_dir "$DOTFILES_DIR/hypr" "hypr/.config/hypr"

# Waybar
safe_copy_dir "$DOTFILES_DIR/waybar" "waybar/.config/waybar"

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

# Superfile
mkdir -p "$STOW_DIR/superfile/.config/superfile"
safe_copy "$DOTFILES_DIR/tools/superfile/config.toml" "$STOW_DIR/superfile/.config/superfile/config.toml"

# Rofi (Structure only)
mkdir -p "$STOW_DIR/rofi/.config/rofi"
# If you have custom rofi config, copy it here:
# safe_copy "$DOTFILES_DIR/rofi/your_config.rasi" "$STOW_DIR/rofi/.config/rofi/config.rasi"

# Btop (Structure only)
mkdir -p "$STOW_DIR/btop/.config/btop"
# Copy custom btop.conf if exists

# Bat (Structure only)
mkdir -p "$STOW_DIR/bat/.config/bat"
# Copy custom bat config if exists

# Fonts (User font configuration structure)
mkdir -p "$STOW_DIR/fonts/.config/fontconfig/conf.d"
# Copy custom fontconfig rules if they exist

# Tools (Docker compose etc.)
mkdir -p "$STOW_DIR/tools/$USER_HOME/Tools/linkding"
mkdir -p "$STOW_DIR/tools/$USER_HOME/Tools/stirling_pdf"
safe_copy "$DOTFILES_DIR/tools/linkding/docker-compose.yml" "$STOW_DIR/tools/$USER_HOME/Tools/linkding/docker-compose.yml"
safe_copy "$DOTFILES_DIR/tools/linkding/.env" "$STOW_DIR/tools/$USER_HOME/Tools/linkding/.env"
safe_copy "$DOTFILES_DIR/tools/stirling_pdf/docker-compose.yml" "$STOW_DIR/tools/$USER_HOME/Tools/stirling_pdf/docker-compose.yml"
# Copy .env for stirling if it exists

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
cat << 'EOF' > "$STOW_DIR/git/.gitconfig"
# Generated by setup script from git.nix
[user]
    name = Mathieu
    email = unknown-archi@users.noreply.github.com

[core]
    editor = nano
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
# Add custom scripts path from dotfiles if it exists (relative to HOME after stowing)
if [[ -d "$HOME/.local/bin" && ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  export PATH="$HOME/.local/bin:$PATH"
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
plugins=(git thefuck)

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
# Assuming installed via DNF or manually cloned
# Source Autosuggestions (adjust path if installed differently)
if [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
elif [ -f $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
  source $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
else
  echo "[Warning] zsh-autosuggestions not found."
fi

# Source Syntax Highlighting (adjust path if installed differently)
if [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
elif [ -f $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
else
  echo "[Warning] zsh-syntax-highlighting not found."
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
alias pip='python3 -m pip' # Changed from 'uv pip' as uv might not be installed/preferred
alias venv='python3 -m venv .venv && source .venv/bin/activate' # Simplified venv creation and activation
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
alias alpine='sudo docker run --rm -it -v \"$HOME/VMs/alpine_docker/alpine_data:/mydata\" alpine' # Adjusted mount
# C compilation aliases
alias cc='gcc -Wall -Werror -Wextra'
alias comp='gcc -Wall -Werror -Wextra *.c'
alias runc='comp && ./a.out'
# Custom utility aliases
alias trash='echo "Trash alias overridden by function below."' # Overridden by function
alias codeC='code *.c' # Requires 'code' command (VS Code)
alias open_resume='docker run --rm -p 3000:3000 open-resume' # Requires manual setup of open-resume image

# --- Functions (from sh.nix, excluding NixOS-specific) ---
# cd with zoxide and ls
cd() {
  # Check if argument is provided and if zoxide exists
  if [[ -n "$1" && -x "$(command -v zoxide)" ]]; then
    zoxide cd "$@" && ls # Use zoxide cd, then list
  else
    # Fallback to standard builtin cd if no arg or zoxide missing
    builtin cd "$@" && ls # Use standard cd, then list
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
    echo "Running: git add . && git commit -m \"$commit_message\" && git push"
    git add . && git commit -m "$commit_message" && git push
}

# Safer rm (moves to a temporary trash directory)
rm() {
    local trash_dir=\"/tmp/trash-${USER}\" # User-specific trash
    mkdir -p \"$trash_dir\"
    if [ "$#" -eq 0 ]; then
        echo \"Usage: rm <file1> [file2]...\" >&2
        return 1
    fi
    echo -e \"\\033[1;33mMoving to $trash_dir:\\033[0m $@\"
    # Use mv with --target-directory for robustness
    command mv --target-directory=\"$trash_dir\" -- \"$@\"
    if [ $? -eq 0 ]; then
         echo -e \"\\033[1;32mSuccessfully moved to trash.\\033[0m\"
    else
         echo -e \"\\033[1;31mError moving files to trash.\\033[0m\" >&2
         return 1
    fi
}

# Create a new directory and cd into it
nd(){ mkdir -p -- "$1" && cd -- "$1"; } # Added quotes and -p

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
        python3 -m http.server \"$port\"
    elif command -v python >/dev/null; then
        python -m SimpleHTTPServer \"$port\" # Fallback for older systems
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
  column -s, -t < \"$1\" | less -#2 -N -S
}

# --- Keybindings ---
# History search bindings from sh.nix
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
# Requires zsh-history-substring-search plugin or manual setup:
# Clone if not using plugin manager:
# if [ ! -d \"${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-history-substring-search\" ]; then
#   git clone [https://github.com/zsh-users/zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search) \"${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-history-substring-search\"
# fi
# source \"${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh\"


# --- Tool Initializations ---

# Initialize Zoxide
if command -v zoxide >/dev/null; then
  eval "$(zoxide init zsh)"
else
  echo "[Warning] zoxide not found, 'cd' function will use standard builtin."
fi

# Initialize Fzf keybindings and fuzzy completion
# Check if fzf is installed
if command -v fzf >/dev/null; then
  # Check if fzf zsh files exist (path might vary based on installation)
  FZF_ZSH_PATH=\"/usr/share/fzf/shell/key-bindings.zsh\"
  if [[ ! -f \$FZF_ZSH_PATH ]]; then
    FZF_ZSH_PATH=\"\$HOME/.fzf/shell/key-bindings.zsh\" # Alternative path if installed manually
  fi
  if [[ -f \$FZF_ZSH_PATH ]]; then
    source \"\$FZF_ZSH_PATH\"
  else
    echo \"[Warning] fzf key bindings script not found.\"
  fi

  FZF_COMPLETION_PATH=\"/usr/share/fzf/shell/completion.zsh\"
   if [[ ! -f \$FZF_COMPLETION_PATH ]]; then
    FZF_COMPLETION_PATH=\"\$HOME/.fzf/shell/completion.zsh\" # Alternative path
  fi
  if [[ -f \$FZF_COMPLETION_PATH ]]; then
    source \"\$FZF_COMPLETION_PATH\"
  else
     echo \"[Warning] fzf completion script not found.\"
  fi
else
  echo \"[Warning] fzf not found. Fuzzy completion/bindings unavailable.\"
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
print_success "Generated $STOW_DIR/zsh/.zshrc"

print_info "Configuration file generation complete."

# --- Zsh Setup and Finalization ---

# Install Oh My Zsh if not already installed
OH_MY_ZSH_DIR="$USER_HOME/.oh-my-zsh"
if [ ! -d "$OH_MY_ZSH_DIR" ]; then
    print_info "Installing Oh My Zsh..."
    # Use non-interactive install
    # Ensure curl and git are installed (should be from earlier steps)
    if command -v curl >/dev/null && command -v git >/dev/null; then
        sh -c "$(curl -fsSL [https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"](https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)") "" --unattended || print_error "Oh My Zsh installation failed."
        # The install script might change the shell, but we'll set it explicitly later
    else
        print_error "curl or git not found. Cannot install Oh My Zsh automatically."
    fi
else
    print_info "Oh My Zsh already installed."
fi

# Install Powerlevel10k Theme for Oh My Zsh if not installed
P10K_DIR="${ZSH_CUSTOM:-$OH_MY_ZSH_DIR/custom}/themes/powerlevel10k"
if [ ! -d "$P10K_DIR" ]; then
    print_info "Installing Powerlevel10k theme..."
    if command -v git >/dev/null; then
        git clone --depth=1 [https://github.com/romkatv/powerlevel10k.git](https://github.com/romkatv/powerlevel10k.git) "$P10K_DIR" || print_error "Powerlevel10k installation failed."
        # Note: The .zshrc generated earlier expects .p10k.zsh in $HOME.
        # P10k wizard should run on first Zsh launch if .p10k.zsh doesn't exist.
        # We copied the existing .p10k.zsh to the stow dir, so it should be linked.
    else
        print_error "git not found. Cannot install Powerlevel10k automatically."
    fi
else
    print_info "Powerlevel10k theme already installed."
fi

# Install zsh-autosuggestions if not installed by package manager (alternative)
# ZSH_AUTOSUGGEST_DIR="${ZSH_CUSTOM:-$OH_MY_ZSH_DIR/custom}/plugins/zsh-autosuggestions"
# if [ ! -d "$ZSH_AUTOSUGGEST_DIR" ]; then
#     print_info "Installing zsh-autosuggestions plugin..."
#     git clone [https://github.com/zsh-users/zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) "$ZSH_AUTOSUGGEST_DIR" || print_error "zsh-autosuggestions installation failed."
# else
#      print_info "zsh-autosuggestions plugin already installed."
# fi

# Install zsh-syntax-highlighting if not installed by package manager (alternative)
# ZSH_SYNTAX_HIGHLIGHT_DIR="${ZSH_CUSTOM:-$OH_MY_ZSH_DIR/custom}/plugins/zsh-syntax-highlighting"
# if [ ! -d "$ZSH_SYNTAX_HIGHLIGHT_DIR" ]; then
#     print_info "Installing zsh-syntax-highlighting plugin..."
#     git clone [https://github.com/zsh-users/zsh-syntax-highlighting.git](https://github.com/zsh-users/zsh-syntax-highlighting.git) "$ZSH_SYNTAX_HIGHLIGHT_DIR" || print_error "zsh-syntax-highlighting installation failed."
# else
#      print_info "zsh-syntax-highlighting plugin already installed."
# fi

# --- Stow Linking ---
print_info "Running Stow to link configuration files..."
if command -v stow >/dev/null; then
    # Ensure we are in the Stow directory
    pushd "$STOW_DIR" > /dev/null || { print_error "Could not change directory to $STOW_DIR"; exit 1; }

    # Stow packages one by one for better error handling
    for pkg in "${STOW_PACKAGES[@]}"; do
        if [ -d "$pkg" ]; then
            print_info "Stowing package: $pkg"
            # Use --restow to update links and handle existing files if needed
            # Use --target=$USER_HOME to specify the target directory
            stow --restow --target="$USER_HOME" "$pkg"
            if [ $? -ne 0 ]; then
                print_warning "Stow command failed for package: $pkg. Check for conflicts."
                # Optionally, add --adopt flag if you want Stow to adopt existing files into the stow dir
                # stow --adopt --restow --target="$USER_HOME" "$pkg"
            else
                print_success "Successfully stowed $pkg."
            fi
        else
            print_warning "Stow package directory not found, skipping: $STOW_DIR/$pkg"
        fi
    done

    popd > /dev/null || print_warning "Could not return from Stow directory."
else
    print_error "Stow command not found. Cannot link dotfiles."
fi
print_info "Stow linking process complete."

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
if command -v systemctl >/dev/null && dnf list installed docker-ce &>/dev/null; then
    print_info "Configuring Docker service..."
    sudo systemctl enable docker
    sudo systemctl start docker
    # Add user to docker group (requires logout/login or newgrp docker)
    if getent group docker > /dev/null; then
        print_info "Adding user $USERNAME to the 'docker' group..."
        sudo usermod -aG docker "$USERNAME"
        print_warning "User $USERNAME added to the docker group. You need to log out and back in, or run 'newgrp docker' in your terminal for this change to take effect."
    else
        print_warning "Docker group not found. Skipping adding user to group."
    fi
    print_success "Docker service enabled and started."
else
    print_info "Docker not installed or systemctl not found. Skipping Docker service configuration."
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
        print_warning "User $USERNAME added to the libvirt group. You need to log out and back in for this change to take effect."
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
print_info "- Oh My Zsh and Powerlevel10k installed."
print_info "- Configurations linked using Stow."
print_info "- Default shell likely changed to Zsh (logout/login required)."
print_info "- Docker & Libvirt services configured (if installed, logout/login may be needed for group changes)."

print_warning "\nImportant Next Steps:"
print_warning "1. Review script output for any warnings or errors."
print_warning "2. Manually copy your SSH keys (~/.ssh/id_*) to $USER_HOME/.ssh/ and set permissions (chmod 600 private, 644 public)."
print_warning "3. Log out and log back in for all changes (shell, groups) to take full effect."
print_warning "4. Launch Zsh. Powerlevel10k configuration wizard might run if needed."
print_warning "5. Verify your applications and configurations are working as expected."
print_warning "6. Consider rebooting to ensure all services and drivers are loaded correctly."

exit 0