# NightDE — what to install on a new Fedora machine

## From Fedora repos
    sudo dnf install -y hyprland hyprlock waybar dunst rofi kitty wlogout \
        grim slurp wl-clipboard wtype brightnessctl playerctl pavucontrol \
        nwg-look qt6ct nautilus \
        xdg-desktop-portal-hyprland xdg-desktop-portal-gtk bluez \
        neovim ripgrep fd-find gcc make unzip curl tar tree-sitter-cli \
        nodejs npm golang cargo dbus-devel python3 \
        google-rubik-fonts
    sudo systemctl enable --now bluetooth

## From COPR / other sources
- **awww** (wallpaper daemon) — COPR
- **cliphist** (clipboard history) — COPR `tofik/sway` (or `go install go.senan.xyz/cliphist@latest`)
- **eww** — binary kept in this project at `.local/bin/eww`
- **bluetui** (Bluetooth TUI) — `cargo install bluetui`
- **wifitui** (Wi-Fi TUI) — Go: installed to `~/go/bin/wifitui`
- **JetBrainsMono Nerd Font** — from nerd-fonts releases into `~/.local/share/fonts`

## Themes (run `Scripts/export-configs.sh --with-themes` to keep copies in the project)
- GTK: Kanagawa GTK theme (`~/.themes`)
- Icons: WhiteSur-dark — `git clone https://github.com/vinceliuice/WhiteSur-icon-theme && ./install.sh`
- Cursor: Bibata Modern Ice — Bibata_Cursor GitHub release `Bibata-Modern-Ice.tar.xz` into `~/.local/share/icons`

## After installing configs
- `hyprctl reload` or log out / in
- Neovim: open `nvim` once — plugins, language servers and parsers install themselves
