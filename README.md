<h1 align="center">Retrilz's Dotfiles</h1>

<table align="center">
   <tr>
      <td colspan="3" align="center">
         <img src="https://share.rzx.ovh/go/rdots-general?v=2" width="fit"><br>
         <sub><b>General</b></sub>
      </td>
   </tr>
   <tr>
      <td align="center">
         <img src="https://share.rzx.ovh/go/rdots-hyprlock" width="fit"><br>
         <sub><b>Hyprlock</b></sub>
      </td>
      <td align="center">
         <img src="https://share.rzx.ovh/go/rdots-terminals?v=2" width="fit"><br>
         <sub><b>Terminals</b></sub>
      </td>
  </tr>
  <tr>
      <td colspan="3" align="center">
         <img src="https://share.rzx.ovh/go/rdots-gtk-qt?v=2" width="fit"><br>
         <sub><b>GTK & Qt</b></sub>
      </td>
   </tr>
</table>

<div align="center">
  <p>【 🇬🇧 English 】 <a href="./README-ru.md">【 🇷🇺 Русский 】</a></p>
   <img alt="Last README modification" src="https://img.shields.io/github/last-commit/retrilzzy/dotfiles?path=README.md&style=for-the-badge&logo=readdotcv&logoColor=ffff&label=Last%20README%20modification&labelColor=0D1117&color=0D1117">
</div>

> [!WARNING]  
> My configs are not designed for universal use. While the installation script is automated, manual adjustments may be required. I do not guarantee the correct operation of the configs or software on your system.

# Installation

> [!NOTE]
> You must have a working Hyprland before installation.

> [!IMPORTANT]  
> The installation script has only been tested on **Arch Linux**.

1.  **System update:**

    ```bash
    sudo pacman -Syu
    ```

2.  **Run the [installation script](./Scripts/install.sh):**

    ```bash
    bash <(curl -s https://raw.githubusercontent.com/retrilzzy/dotfiles/main/Scripts/install.sh)
    ```

    This command will:
    - Install [necessary packages](#dependencies).
    - Clone this repository to `~/dotfiles`.
    - Create a backup of your existing configs in `~/.config-backups/$date_time`.
    - Apply new configs.

### Script Options

The installation script supports the following options:

| Option | Description |
| :--- | :--- |
| `-u`, `--unattended` | Run in unattended mode (no prompts, assumes yes). |
| `-f`, `--force` | Bypass checks (e.g., Wayland session). |
| `-l`, `--log FILE` | Specify a custom log file (default: `install_TIMESTAMP.log`). |
| `-h`, `--help` | Show help message. |

Example:
```bash
# Run unattended
bash <(curl -s https://raw.githubusercontent.com/retrilzzy/dotfiles/main/Scripts/install.sh) -u
```

## After installation

**General:**

- Add your wallpapers to `~/Pictures/Wallpapers`.
- Run `p10k configure` to configure the terminal theme.
- Cleanup `~/.zshrc` plugins if needed.

**PC users:**

- Disable the `custom/backlight` Waybar module in `~/.config/waybar/config.jsonc`.

## Restoring config backup

To restore a previous configuration:

```bash
~/dotfiles/Scripts/restore.sh
```

# Features & Configuration

## Hyprland

Dynamic tiling Wayland compositor.
- Configs: `~/.config/hypr/hyprland/`
- **[Keybinds](#keybinds)**

## Core Components

| Component | Description | Config Location |
| :--- | :--- | :--- |
| **[Waybar](#waybar)** | Status bar | `~/.config/waybar/` |
| **[Hyprlock](#hyprlock)** | Lock screen | `~/.config/hypr/hyprlock.conf` |
| **[Hypridle](#hypridle)** | Idle daemon | `~/.config/hypr/hypridle.conf` |
| **[Vicinae](#vicinae)** | Launcher | `~/.config/vicinae/` |
| **[Wlogout](#wlogout)** | Logout menu | `~/.config/wlogout/` |
| **[SwayNC](#swaync)** | Notifications | `~/.config/swaync/` |

## Appearance

- **GTK:** [nwg-look](https://github.com/nwg-piotr/nwg-look) with `adw-gtk3-dark` theme.
- **Qt:** Configured via `qt5ct`/`qt6ct` with `Darkly` theme.
- **Icons:** [Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme).
- **Cursor:** [Bibata Modern Classic](https://github.com/ful1e5/Bibata_Cursor).
- **Fonts:** Noto, JetBrains Mono Nerd, Meslo Nerd, Inter.
- **Wallpapers:** Managed by [Waypaper](https://github.com/anufrievroman/waypaper) & `swww`.

## Terminal

- **Emulator:** [Kitty](https://sw.kovidgoyal.net/kitty)
- **Shell:** [Zsh](https://www.zsh.org/) with [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh)
- **Theme:** [Powerlevel10k](https://github.com/romkatv/powerlevel10k)
- **Tools:** `lsd`, `fastfetch`

<details><summary><b>Kitty Keybinds</b></summary>
<br>

| Keys | Action |
| :--- | :--- |
| <kbd>Ctrl</kbd> + <kbd>A</kbd> > <kbd>X</kbd> | Close active window |
| <kbd>Ctrl</kbd> + <kbd>A</kbd> > <kbd>]</kbd> / <kbd>[</kbd> | Next/Prev window |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>T</kbd> | New window (horizontal split) |
| <kbd>F4</kbd> | Split window |
| <kbd>Ctrl</kbd> + <kbd>A</kbd> > <kbd>Z</kbd> | Zoom window |
| <kbd>F11</kbd> | Fullscreen |

</details>

# Keybinds

<details>
   <summary><b>Application Launch</b></summary>

| Keys | Action |
| :--- | :--- |
| <kbd>Super</kbd> + <kbd>W</kbd> | Terminal (Kitty) |
| <kbd>Super</kbd> + <kbd>R</kbd> | Application menu (Vicinae) |
| <kbd>Super</kbd> + <kbd>E</kbd> | File manager (Nautilus) |
| <kbd>Super</kbd> + <kbd>C</kbd> | Code editor (VSCodium*) |
| <kbd>Super</kbd> + <kbd>B</kbd> | Browser (Brave*) |
| <kbd>Super</kbd> + <kbd>N</kbd> | Notification center |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>P</kbd> | Wallpaper selector |

*\* Not installed automatically.*
</details>

<details>
   <summary><b>Window Management</b></summary>

| Keys | Action |
| :--- | :--- |
| <kbd>Super</kbd> + <kbd>Q</kbd> | Close window |
| <kbd>Super</kbd> + <kbd>F</kbd> | Toggle float |
| <kbd>Super</kbd> + <kbd>A</kbd> | Maximize |
| <kbd>Alt</kbd> + <kbd>Tab</kbd> | Switch window |
| <kbd>Super</kbd> + <kbd>Arrows</kbd> | Move focus |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>Arrows</kbd> | Move window |

</details>

<details>
   <summary><b>System</b></summary>

| Keys | Action |
| :--- | :--- |
| <kbd>Super</kbd> + <kbd>L</kbd> | Lock screen |
| <kbd>Print</kbd> | Screenshot (entire screen) |
| <kbd>Shift</kbd> + <kbd>Print</kbd> | Screenshot (area) |
| <kbd>Super</kbd> + <kbd>M</kbd> | Mute Mic |

</details>

# Detailed Dependencies

Packages installed by `install.sh`.

<details>
<summary><b>System, Interface & Tools</b></summary>

| Package | Description |
| :--- | :--- |
| `hyprlock`, `hypridle`, `hyprshot` | Core Hyprland tools |
| `waybar`, `swaync`, `wlogout` | UI components |
| `vicinae`, `waypaper`, `swww` | Launchers & Wallpapers |
| `kitty`, `zsh`, `starship` | Terminal environment |
| `nwg-look` | GTK configuration |
| `grim`, `slurp`, `flameshot` | Screenshot tools |
| `brightnessctl`, `playerctl`, `pavucontrol` | Hardware control |
| `nautilus`, `trash-cli` | File management |
| `bluez`, `blueman`, `networkmanager` | Connectivity |
| `pipewire`, `pipewire-pulse` | Audio |
| `xdg-desktop-portal-*` | Portals |

</details>

<details>
<summary><b>Theming & Fonts</b></summary>

| Package | Description |
| :--- | :--- |
| `adw-gtk-theme` | GTK Theme |
| `qt5ct`, `qt6ct`, `darkly-bin` | Qt Theming |
| `papirus-icon-theme` | Icon Theme |
| `inter-font`, `noto-fonts-*` | System Fonts |
| `ttf-jetbrains-mono-nerd` | Monospace Font |

</details>
