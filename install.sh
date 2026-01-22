#!/usr/bin/env bash
clear

REPO="${HOME}/kde"
CFG_PATH="${REPO}/.config"

installPackages() {
  sudo pacman -Syu

  local packages=("gum" "make" "debugedit" "fakeroot" "networkmanager-openvpn" "zip" "unzip" "gunzip" "man" "libreoffice" "fastfetch" "glow" "grub" "os-prober" "ntfs-3g" "reflector" "tree" "lazygit" "ufw" "zsh" "unzip" "wget" "eza" "gamemode" "steam" "zoxide" "fzf" "bat" "jdk21-openjdk" "docker" "ripgrep" "fd" "starship" "helix" "rustup" "wine" "python-pip" "pam-u2f" "pipewire-pulse" "pipewire-alsa" "pipewire-jack" "ttf-font-awesome" "git-delta" "ttf-nerd-fonts-symbols" "ttf-jetbrains-mono-nerd" "noto-fonts-emoji" "wireplumber" "libfido2" "xdg-desktop-portal-gtk" "xdg-desktop-portal-wlr" "gdb" "pacman-contrib" "libimobiledevice" "usbmuxd" "gvfs-gphoto2" "ifuse" "openvpn" "ncdu" "texlive" "inetutils" "net-tools" "wl-clipboard" "jq" "nodejs" "npm" "nm-connection-editor" "github-cli" "systemd-resolved" "tealdeer" "wireguard-tools" "linux-headers" "ffmpeg4.4" "ark" "dolphin" "dolphin-plugins" "dragon" "elisa" "ffmpegthumbs" "isoimagewriter" "konsole" "okular" "plasma" "gamescope" "cmake" "meson" "pkg-config" "cpio" "bluez" "bluez-obex" "gcc" "power-profiles-daemon" "plymouth")

  for pkg in "${packages[@]}"; do
    sudo pacman -S --needed --noconfirm "${pkg}"
  done

  rustup default stable
}

install_helix_utils() {
  local formatter=("stylua" "prettier" "beautysh" "python-black" "gofumpt" "clang-format-all-git" "dockerfmt" "yamlfmt" "google-java-format")
  local servers=("rust-analyzer" "jdtls" "bash-language-server" "docker-ls" "hyprls-git" "jedi-language-server" "vscode-css-languageserver" "vscode-html-languageserver" "gopls" "gradle-language-server" "texlab" "yaml-language-server" "vscode-json-languageserver")

  for pkg in "${formatter[@]}"; do
    yay -S --needed --noconfirm "${pkg}"
  done

  for pkg in "${servers[@]}"; do
    yay -S --needed --noconfirm "${pkg}"
  done
}

installAurPackages() {
  local packages=("google-chrome" "konsave" "visual-studio-code-bin" "xpadneo-dkms" "openvpn3" "xwayland-satellite" "localsend-bin" "openvpn-update-systemd-resolved" "lazydocker" "ufw-docker" "qt-heif-image-plugin" "luajit-tiktoken-bin" "vesktop")
  for pkg in "${packages[@]}"; do
    yay -S --noconfirm "${pkg}"
  done
}

installYay() {
  if ! command -v yay >/dev/null 2>&1; then
    cwd=$(pwd)
    echo ">>> Installing yay..."
    git clone https://aur.archlinux.org/yay.git "${HOME}/yay"
    cd "${HOME}/yay"
    makepkg -si
    cd "${cwd}"
  fi
}

installDeepCoolDriver() {
  local deepcool
  echo ">>> Do you want to install DeepCool CPU-Fan driver?"
  deepcool=$(gum choose "Yes" "No")
  if [[ "${deepcool}" == "Yes" ]]; then
    sudo cp "${REPO}/DeepCool/deepcool-digital-linux" "/usr/sbin"
    sudo cp "${REPO}/DeepCool/deepcool-digital.service" "/etc/systemd/system"
    sudo systemctl enable deepcool-digital
  fi
}

configure_git() {
  local answer name email ssh
  echo ">>> Want to configure git?"
  answer=$(gum choose "Yes" "No")
  if [[ "${answer}" == "Yes" ]]; then
    name=$(gum input --prompt ">>> What is your user name? ")
    git config --global user.name "${name}"
    email=$(gum input --prompt ">>> What is your email? ")
    git config --global user.email "${email}"
    git config --global pull.rebase true
  fi

  git config --global core.pager 'delta -n'
  git config --global interactive.diffFilter 'delta --color-only -n'
  git config --global delta.navigate true
  git config --global merge.conflictStyle zdiff3

  echo ">>> Want to create a ssh-key?"
  ssh=$(gum choose "Yes" "No")
  if [[ "${ssh}" == "Yes" ]]; then
    ssh-keygen -t ed25519 -C "${email}"
  fi
}

detect_nvidia() {
  local gpu
  gpu=$(lspci | grep -i '.* vga .* nvidia .*')

  shopt -s nocasematch

  if [[ ${gpu} == *' nvidia '* ]]; then
    echo ">>> Nvidia GPU is present"
    gum spin --spinner dot --title "Installaling nvidia drivers now..." -- sleep 2
    sudo pacman -S --needed --noconfirm nvidia-open nvidia-utils nvidia-settings
  else
    echo ">>> It seems you are not using a Nvidia GPU"
    echo ">>> If you have a Nvidia GPU then download the drivers yourself please :)"
  fi
}

get_wallpaper() {
  local ans
  echo ">>> Do you want to download cool wallpaper?"
  ans=$(gum choose "Yes" "No")
  if [[ "${ans}" == "Yes" ]]; then
    if [ ! -d "${HOME}/Pictures/Wallpaper" ]; then
      mkdir -p "${HOME}/Pictures/Wallpaper"
    fi
    git clone "https://github.com/HanmaDevin/Wallpapes.git" "${HOME}/Wallpapes"
    cp ~/Wallpapes/* "${HOME}/Pictures/Wallpaper"
    rm -rf "${HOME}/Wallpapes"
    rm -rf "${HOME}/Pictures/Wallpaper/.git"
  fi
}

setup_firewall() {
  gum spin --spinner dot --title "Firewall Setup..." -- sleep 2
  # Allow nothing in, everything out
  sudo ufw default deny incoming
  sudo ufw default allow outgoing

  # Allow ports for LocalSend
  sudo ufw allow 53317/udp
  sudo ufw allow 53317/tcp

  sudo ufw allow KDEConnect

  # Allow Docker containers to use DNS on host
  sudo ufw allow in proto udp from 172.16.0.0/12 to 172.17.0.1 port 53 comment 'allow-docker-dns'

  # Turn on the firewall
  sudo ufw --force enable

  # Enable UFW systemd service to start on boot
  sudo systemctl enable ufw

  # Turn on Docker protections
  sudo ufw-docker install
  sudo ufw reload

  gum spin --spinner "globe" --title "Done! Press any key to close..." -- bash -c 'read -n 1 -s'
}

copy_config() {
  local theme bat

  gum spin --spinner dot --title "Creating Home..." -- sleep 2
  mkdir -p "${HOME}/Desktop"
  mkdir -p "${HOME}/Downloads"
  mkdir -p "${HOME}/Pictures"
  mkdir -p "${HOME}/Videos"

  if [[ ! -d "${HOME}/Pictures/Screenshots" ]]; then
    mkdir -p "${HOME}/Pictures/Screenshots"
  fi

  cp "${REPO}/.zshrc" "${HOME}"
  cp -r "${CFG_PATH}" "${HOME}"
  cp -r "${REPO}/.local/share/gnome-shell/extensions" "${HOME}/.local/share/gnome-shell"
  get_wallpaper

  sudo cp -r "${REPO}/fonts" "/usr/share"
  sudo cp "${REPO}/etc/pacman.conf" "/etc/pacman.conf"
  sudo cp -r "${REPO}/plymouth/arch-mac-style" "/usr/share/plymouth/themes"
  sudo cp -r "${REPO}/grub/Stylish-4k" "/boot/grub/themes"
  sudo cp "${REPO}/etc/default/grub" "/etc/default"
  sudo plymouth-set-default-theme -R "arch-mac-style"
  sudo grub-mkconfig -o "/boot/grub/grub.cfg"
  sudo cp -r "${REPO}/etc/xdg" "/etc"
  sudo cp -r "${REPO}/icons" "/usr/share"

  echo ">>> Trying to change the shell..."
  chsh -s "/bin/zsh"
}

MAGENTA='\033[0;35m'
NONE='\033[0m'

# Header
echo -e "${MAGENTA}"
cat <<"EOF"
   ____         __       ____
  /  _/__  ___ / /____ _/ / /__ ____
 _/ // _ \(_-</ __/ _ `/ / / -_) __/
/___/_//_/___/\__/\_,_/_/_/\__/_/

EOF

echo "HanmaDevin HyprLand Setup"
echo -e "${NONE}"
while true; do
  read -r -p ">>> Do you want to start the installation now? (y/n): " yn
  case ${yn} in
    [Yy]*)
      echo ">>> Installation started."
      echo
      break
      ;;
    [Nn]*)
      echo ">>> Installation canceled"
      exit
      ;;
    *)
      echo ">>> Please answer yes or no."
      ;;
  esac
done

echo ">>> Installing required packages..."
installPackages
installYay
installAurPackages
install_helix_utils
copy_config
detect_nvidia
installDeepCoolDriver
configure_git
"${REPO}/bin/hyprdev-setup-fingerprint"

konsave -i "${REPO}/devin.knsv"
konsave -a devin

sudo systemctl enable reflector
sudo systemctl enable bluetooth
sudo systemctl enable sddm

echo -e "${MAGENTA}"
cat <<"EOF"
    ____       __                __  _
   / __ \___  / /_  ____  ____  / /_(_)___  ____ _   ____  ____ _      __
  / /_/ / _ \/ __ \/ __ \/ __ \/ __/ / __ \/ __ `/  / __ \/ __ \ | /| / /
 / _, _/  __/ /_/ / /_/ / /_/ / /_/ / / / / /_/ /  / / / / /_/ / |/ |/ /
/_/ |_|\___/_.___/\____/\____/\__/_/_/ /_/\__, /  /_/ /_/\____/|__/|__/
                                         /____/
EOF
echo "and thank you for choosing my config :)"
echo -e "${NONE}"

if gum confirm "Reboot System?"; then
  systemctl reboot
else
  exit 0
fi
