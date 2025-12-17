#!/bin/bash

set -euo pipefail

# Default Configuration
DOTFILES_DIR="$HOME/dotfiles"
LOG_FILE="install_$(date +%Y%m%d_%H%M%S).log"
UNATTENDED=false
FORCE=false

# Colors
RED="\033[1;31m"
YELLOW="\033[1;33m"
GREEN="\033[1;32m"
CYAN="\033[1;36m"
BLUE="\033[1;34m"
RESET="\033[0m"

# State tracking for summary
declare -A STEPS_STATUS

# --- Helper Functions ---

# Logging function
log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    local color="$RESET"

    case "$level" in
        INFO) color="$BLUE" ;;
        SUCCESS) color="$GREEN" ;;
        WARN) color="$YELLOW" ;;
        ERROR) color="$RED" ;;
    esac

    # Print to console
    echo -e "${color}[${level}] ${message}${RESET}"

    # Log to file (strip colors)
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Print a section header
print_section() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "   $1"
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo "" >> "$LOG_FILE"
    echo "--- Section: $1 ---" >> "$LOG_FILE"
}

# Error handler
error_handler() {
    local line_no=$1
    local command=$2
    log ERROR "Error occurred at line $line_no: command '$command' failed."
    print_summary
    exit 1
}

trap 'error_handler ${LINENO} "$BASH_COMMAND"' ERR

# Usage information
usage() {
    echo -e "Usage: $0 [OPTIONS]"
    echo -e "Options:"
    echo -e "  -u, --unattended    Run in unattended mode (no prompts, assumes yes)"
    echo -e "  -f, --force         Bypass checks (e.g., Wayland session)"
    echo -e "  -l, --log FILE      Specify log file (default: install_TIMESTAMP.log)"
    echo -e "  -h, --help          Show this help message"
    exit 0
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -u|--unattended)
                UNATTENDED=true
                shift
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -l|--log)
                LOG_FILE="$2"
                shift 2
                ;;
            -h|--help)
                usage
                ;;
            *)
                log ERROR "Unknown option: $1"
                usage
                ;;
        esac
    done
}

# --- Core Functions ---

# Check prerequisites
check_prerequisites() {
    print_section "Checking Prerequisites"

    # Check root
    if [ "$EUID" -eq 0 ]; then
        log ERROR "This script should not be run as root or with sudo. Please run it as a regular user."
        exit 1
    fi

    # Check Wayland
    if [ -z "${WAYLAND_DISPLAY:-}" ] && [ "$FORCE" = false ]; then
        log ERROR "The script must be run in an active Wayland session (Hyprland). Use --force to bypass."
        exit 1
    elif [ -z "${WAYLAND_DISPLAY:-}" ]; then
        log WARN "Running outside of Wayland session (Bypassed by --force)."
    fi

    # Initialize sudo
    log INFO "Requesting sudo privileges..."
    if sudo -v; then
        log SUCCESS "Sudo privileges granted."
    else
        log ERROR "Failed to obtain sudo privileges."
        exit 1
    fi

    # Keep sudo alive
    (while true; do sudo -v; sleep 60; done) &
    SUDO_PID=$!
    trap 'kill $SUDO_PID' EXIT

    STEPS_STATUS["Prerequisites"]="Success"
}

# Install packages with pacman
install_pacman() {
    local category="$1"
    shift
    local packages=("$@")

    log INFO "Checking packages for: $category"

    local to_install_pacman=()
    for pkg in "${packages[@]}"; do
        if ! pacman -Qq "$pkg" &>/dev/null; then
            log INFO "Will install: ${pkg}"
            to_install_pacman+=("$pkg")
        else
            log INFO "Skipped (already installed): ${pkg}"
        fi
    done

    if [ ${#to_install_pacman[@]} -gt 0 ]; then
        log INFO "Installing Pacman packages: ${to_install_pacman[*]}"
        if sudo pacman -S --noconfirm --needed "${to_install_pacman[@]}"; then
            log SUCCESS "Pacman packages installed successfully."
        else
            log ERROR "Failed to install packages: ${to_install_pacman[*]}"
            STEPS_STATUS["Install $category"]="Failed"
            return 1
        fi
    else
        log SUCCESS "All packages for $category are already installed."
    fi
    STEPS_STATUS["Install $category"]="Success"
}

# Install packages with yay
install_yay_packages() {
    local category="$1"
    shift
    local packages=("$@")

    log INFO "Checking AUR packages for: $category"

    local to_install_yay=()
    for pkg in "${packages[@]}"; do
        if ! yay -Qq "$pkg" &>/dev/null; then
            log INFO "Will install (AUR): ${pkg}"
            to_install_yay+=("$pkg")
        else
            log INFO "Skipped (already installed): ${pkg}"
        fi
    done

    if [ ${#to_install_yay[@]} -gt 0 ]; then
        log INFO "Installing AUR packages (Yay): ${to_install_yay[*]}"
        if yay -S --noconfirm "${to_install_yay[@]}"; then
             log SUCCESS "AUR packages installed successfully."
        else
             log ERROR "Failed to install AUR packages: ${to_install_yay[*]}"
             STEPS_STATUS["Install AUR $category"]="Failed"
             return 1
        fi
    else
        log SUCCESS "All AUR packages for $category are already installed."
    fi
    STEPS_STATUS["Install AUR $category"]="Success"
}

# Clone or update the dotfiles repository
clone_repo() {
    print_section "Cloning or updating dotfiles repository"
    if [ -d "$DOTFILES_DIR" ]; then
        log INFO "Dotfiles directory already exists. Attempting to pull latest changes."
        pushd "$DOTFILES_DIR" >/dev/null
        if git pull --rebase --autostash; then
            log SUCCESS "Dotfiles updated successfully."
        else
            log ERROR "Failed to pull dotfiles. Please check your internet connection or repository access."
            popd >/dev/null
            exit 1
        fi
        popd >/dev/null
    else
        log INFO "Cloning dotfiles repository."
        if git clone --depth=10 https://github.com/retrilzzy/dotfiles.git "$DOTFILES_DIR"; then
            log SUCCESS "Dotfiles cloned successfully."
        else
            log ERROR "Failed to clone dotfiles. Please check your internet connection or repository access."
            exit 1
        fi
    fi
    STEPS_STATUS["Clone Repo"]="Success"
}

# Configure pacman and update the system
setup_pacman() {
    print_section "Configuring Pacman"

    local confirm="n"
    if [ "$UNATTENDED" = true ]; then
        confirm="Y"
        log INFO "Unattended mode: Overwriting /etc/pacman.conf automatically."
    else
        read -rp "$(echo -e "${YELLOW}Overwrite /etc/pacman.conf? (Y/n): ${RESET}")" input
        confirm=${input:-Y}
    fi

    if [[ "$confirm" =~ ^([Yy]|[Yy][Ee][Ss])$ ]]; then
        log INFO "Creating a backup of /etc/pacman.conf to /etc/pacman.conf.bak"
        sudo cp /etc/pacman.conf /etc/pacman.conf.bak 2>/dev/null || true

        log INFO "Applying new pacman.conf"
        sudo cp "$DOTFILES_DIR/Configs/etc/pacman.conf" /etc/pacman.conf
        log SUCCESS "Pacman.conf overwritten."
    else
        log WARN "Pacman.conf overwrite skipped."
    fi

    log INFO "Updating system"
    if sudo pacman -Syu --noconfirm; then
        log SUCCESS "System updated."
    else
        log ERROR "Failed to update system."
        STEPS_STATUS["Setup Pacman"]="Failed"
        return 1
    fi

    STEPS_STATUS["Setup Pacman"]="Success"
}

# Install yay if it is not already installed
ensure_yay() {
    if ! command -v yay &>/dev/null; then
        print_section "Installing Yay"

        log INFO "Installing base-devel"
        sudo pacman -S --noconfirm --needed base-devel

        local tmp_dir
        tmp_dir=$(mktemp -d)
        log INFO "Cloning yay to $tmp_dir"
        git clone --depth=1 https://aur.archlinux.org/yay.git "$tmp_dir"

        pushd "$tmp_dir" >/dev/null
        log INFO "Building yay"
        makepkg -si --noconfirm
        popd >/dev/null

        rm -rf "$tmp_dir"

        if command -v yay &>/dev/null; then
            log SUCCESS "Yay installed successfully!"
        else
            log ERROR "yay installation failed."
            exit 1
        fi
    else
        log INFO "Yay is already installed"
    fi
    STEPS_STATUS["Ensure Yay"]="Success"
}

# Install Bibata cursor
install_bibata_cursor() {
    print_section "Installing Bibata cursor"

    log INFO "Installing Bibata cursor..."
    local tmp_dir
    tmp_dir=$(mktemp -d)

    if curl -L "https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata-Modern-Classic.tar.xz" -o "$tmp_dir/bibata.tar.xz"; then
        tar -xf "$tmp_dir/bibata.tar.xz" -C "$tmp_dir"
        sudo cp -r "$tmp_dir/Bibata-Modern-Classic" /usr/share/icons/
        log SUCCESS "Bibata cursor installed."
    else
        log ERROR "Failed to download Bibata cursor."
        STEPS_STATUS["Bibata Cursor"]="Failed"
        rm -rf "$tmp_dir"
        return 1
    fi
    rm -rf "$tmp_dir"
    STEPS_STATUS["Bibata Cursor"]="Success"
}

# Setup Zsh, Oh My Zsh and plugins
setup_zsh() {
    print_section "Setting up Zsh"

    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        log INFO "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || true
    else
        log INFO "Oh My Zsh already installed."
    fi

    if [ "$SHELL" != "$(which zsh)" ]; then
        log INFO "Changing default shell to zsh..."
        if sudo chsh -s "$(which zsh)" "$USER"; then
             log SUCCESS "Shell changed to zsh."
        else
             log WARN "Failed to change shell. You may need to do this manually."
        fi
    else
        log INFO "Shell is already zsh."
    fi

    log INFO "Installing Zsh plugins/themes..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" 2>/dev/null || log INFO "powerlevel10k already exists"
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" 2>/dev/null || log INFO "zsh-syntax-highlighting already exists"
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" 2>/dev/null || log INFO "zsh-autosuggestions already exists"

    STEPS_STATUS["Setup Zsh"]="Success"
}

# Backup existing configurations
backup_configs() {
    print_section "Backing up existing configurations"

    local date_now
    date_now=$(date +%Y-%m-%d_%H-%M-%S)
    local backup_dir="$HOME/.config-backups/$date_now"

    mkdir -p "$backup_dir/.config" "$backup_dir/etc"

    shopt -s nullglob
    for dir in "$DOTFILES_DIR"/Configs/.config/*; do
        local name
        name=$(basename "$dir")

        if [ "$name" = "discord" ]; then
            continue
        fi

        if [ -d "$HOME/.config/$name" ]; then
            log INFO "Copying $HOME/.config/$name to $backup_dir/.config/"
            cp -a "$HOME/.config/$name" "$backup_dir/.config/"
        fi
    done

    local home_files=(".zshrc" ".p10k.zsh" ".nanorc")
    for file in "${home_files[@]}"; do
        if [ -f "$HOME/$file" ]; then
            log INFO "Copying $HOME/$file to $backup_dir/"
            cp -a "$HOME/$file" "$backup_dir/"
        fi
    done

    for dir in "$DOTFILES_DIR"/Configs/etc/*; do
        local name
        name=$(basename "$dir")
        if [ -d "/etc/$name" ]; then
            log INFO "Copying /etc/$name to $backup_dir/etc/"
            cp -a "/etc/$name" "$backup_dir/etc/"
        fi
    done
    shopt -u nullglob

    log SUCCESS "Backup saved to $backup_dir"
    STEPS_STATUS["Backup Configs"]="Success"
}

# Apply new configurations from the dotfiles repository
apply_new_configs() {
    print_section "Applying new configurations"

    log INFO "Copying .config files..."
    cp -a "$DOTFILES_DIR/Configs/.config/." "$HOME/.config/"

    log INFO "Copying home files (.zshrc, etc)..."
    cp "$DOTFILES_DIR/Configs/.zshrc" \
        "$DOTFILES_DIR/Configs/.p10k.zsh" \
        "$DOTFILES_DIR/Configs/.nanorc" "$HOME/"

    log INFO "Copying .local files..."
    cp -a "$DOTFILES_DIR/Configs/.local/." "$HOME/.local/"

    log INFO "Copying /etc files (requires sudo)..."
    sudo cp -a "$DOTFILES_DIR/Configs/etc/." /etc/

    log SUCCESS "New configurations applied."
    STEPS_STATUS["Apply Configs"]="Success"
}

# Run essential services
run_services() {
    print_section "Running services"

    # Only run services if we are in Wayland
    if [ -n "${WAYLAND_DISPLAY:-}" ]; then
        if pgrep -x "waybar" >/dev/null; then
            killall waybar && sleep 1
        fi
        uwsm app -- waybar -c "$HOME/.config/waybar/config.jsonc" -s "$HOME/.config/waybar/styles.css" >/dev/null 2>&1 &
        disown

        if pgrep -x "dunst" >/dev/null; then
            killall dunst && sleep 1
        fi
        uwsm app -- swaync -c "$HOME/.config/swaync/config.json" >/dev/null 2>&1 &
        disown

        uwsm app -- nm-applet >/dev/null 2>&1 &
        disown

        uwsm app -- vicinae server >/dev/null 2>&1 &
        disown

        uwsm app -- swww-daemon >/dev/null 2>&1 &
        disown

        log SUCCESS "Services started."
    else
        log WARN "Skipping service start (Not in Wayland)."
    fi
    STEPS_STATUS["Run Services"]="Success"
}

# Download and set up wallpapers
setup_wallpapers() {
    print_section "Wallpapers"

    local wallpaper_dest="$HOME/Pictures/Wallpapers-test"
    mkdir -p "$wallpaper_dest"

    log INFO "Downloading 5 random wallpapers"
    log INFO "All wallpapers: https://share.rzx.ovh/folder/cmik5z0om005001pc7996irnv"

    if curl -s "https://share.rzx.ovh/api/server/folder/cmik5z0om005001pc7996irnv" | \
        jq -r '.files[].name' | \
        shuf -n 5 | \
        while read -r name; do
            [ -z "$name" ] && continue
            local url="https://share.rzx.ovh/raw/$name"
            log INFO "Downloading wallpaper: $url"
            curl --connect-timeout 5 --max-time 30 -L -s "$url" -o "$wallpaper_dest/$name" || log WARN "Failed to download wallpaper: $name"
        done; then

        log SUCCESS "Wallpapers saved to $wallpaper_dest"
    else
        log WARN "Wallpaper download process encountered issues."
    fi

    mkdir -p "$HOME/.local/share/color-schemes" || true

    if [ -x "$HOME/.config/bin/change-wall.sh" ]; then
        "$HOME/.config/bin/change-wall.sh" "$wallpaper_dest"
        log SUCCESS "Wallpaper set."
    else
        log WARN "Wallpaper change script not found or not executable."
    fi
    STEPS_STATUS["Setup Wallpapers"]="Success"
}

# Apply GTK theme
setup_theme() {
    print_section "Applying theme"

    if [ -n "${WAYLAND_DISPLAY:-}" ]; then
        gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' && \
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

        if nwg-look -a; then
            log SUCCESS "Themes applied via nwg-look."
        else
             log WARN "Failed to apply theme via nwg-look."
        fi
    else
        log WARN "Skipping theme application (Not in Wayland)."
    fi
    STEPS_STATUS["Setup Theme"]="Success"
}

# Reload services after theme and wallpaper changes
reload_services() {
    print_section "Reloading services"

    if [ -n "${WAYLAND_DISPLAY:-}" ]; then
        if pgrep -x "waybar" >/dev/null; then
            killall waybar && sleep 1
        fi
        uwsm app -- waybar -c "$HOME/.config/waybar/config.jsonc" -s "$HOME/.config/waybar/styles.css" >/dev/null 2>&1 &
        disown
        log SUCCESS "Services reloaded."
    else
        log WARN "Skipping service reload (Not in Wayland)."
    fi
    STEPS_STATUS["Reload Services"]="Success"
}

# Print summary
print_summary() {
    print_section "Installation Summary"
    echo -e "${CYAN}Step Status:${RESET}"
    for step in "${!STEPS_STATUS[@]}"; do
        if [ "${STEPS_STATUS[$step]}" == "Success" ]; then
             echo -e "  ${GREEN}✔ ${step}${RESET}"
        else
             echo -e "  ${RED}✖ ${step}${RESET}"
        fi
    done
    echo ""
    echo -e "Log file saved to: ${CYAN}${LOG_FILE}${RESET}"
}

# Main function
main() {
    parse_args "$@"

    # Clear log file
    : > "$LOG_FILE"
    log INFO "Starting installation script..."

    check_prerequisites

    log INFO "Starting installation in 3 seconds..."
    sleep 3

    install_pacman "Git" git

    clone_repo

    setup_pacman

    ensure_yay

    print_section "System and interface"
    install_pacman "System Tools" hyprlock hypridle kitty nwg-look swaync waybar swww hyprshot
    install_yay_packages "System Tools" waypaper wlogout vicinae-bin

    print_section "Utilities and tools"
    install_pacman "Utilities" brightnessctl imagemagick fastfetch grim tar lsd pavucontrol playerctl trash-cli uwsm wl-clipboard wl-clip-persist
    install_yay_packages "Utilities" flameshot-git gpu-screen-recorder nautilus network-manager-applet

    print_section "Networking, audio and portals"
    install_pacman "Networking/Audio" networkmanager bluez blueman pipewire pipewire-pulse pipewire-audio pipewire-alsa polkit-gnome xdg-utils xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-desktop-portal-wlr xdg-desktop-portal-gnome

    print_section "Appearance and themes"
    install_pacman "Themes/Fonts" adw-gtk-theme frameworkintegration inter-font noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra papirus-icon-theme ttf-jetbrains-mono-nerd
    install_yay_packages "Themes/Fonts" matugen-bin qt5ct-kde qt6ct-kde darkly-bin ttf-meslo-nerd-font-powerlevel10k
    install_bibata_cursor

    install_pacman "Shell" zsh
    setup_zsh

    backup_configs
    apply_new_configs
    run_services

    sleep 2
    setup_wallpapers
    setup_theme

    reload_services

    print_summary

    echo -e "${GREEN}Installation complete!${RESET}"
    echo -e "${CYAN}To fully apply the changes, it is recommended to restart the system.${RESET}"

    if [ "$UNATTENDED" = false ]; then
        exec zsh
    fi
}

main "$@"
