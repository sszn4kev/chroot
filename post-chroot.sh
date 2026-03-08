#!/bin/bash

# ==========================================
#  POST-CHROOT: SYSTEM, CONFIGS, & AUR APPS
# ==========================================

USERNAME="starrk"
HOSTNAME="spder-v3"
ROOT_DEV="/dev/sda2"


echo "=========================================="
echo " 1. CREATING USERNAME & HOSTNAME          "
echo "=========================================="
echo "$HOSTNAME" > /etc/hostname
useradd -m -G wheel "$USERNAME"
echo "Set a password for $USERNAME:"
passwd "$USERNAME"

echo "=========================================="
echo " 2. LOCALE & VCONSOLE STUFF               "
echo "=========================================="
ln -sf /usr/share/Europe/Moscow /etc/localtime
hwclock --systohc
echo "en_GB.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_GB.UTF-8" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf

echo "=========================================="
echo " 3. MANUAL VISUDO CONFIGURATION           "
echo "=========================================="
echo "Opening visudo... Please uncomment %wheel ALL=(ALL:ALL) ALL"
echo "Press ENTER to continue..."
read -r
EDITOR=nano visudo

echo "=========================================="
echo " 4. ADDING CACHYOS KEYRING & REPOS        "
echo "=========================================="
# Re-initializing keys for the new system
pacman-key --init
pacman-key --populate archlinux
pacman-key --recv-keys F3B607488DB35A47 --keyserver keyserver.ubuntu.com
pacman-key --lsign-key F3B607488DB35A47
pacman -U --noconfirm 'https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-keyring-20240331-1-any.pkg.tar.zst'
pacman -U --noconfirm 'https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-mirrorlist-22-1-any.pkg.tar.zst'

cat <<EOT > /etc/pacman.conf.new
[cachyos-v3]
Include = /etc/pacman.d/cachyos-v3-mirrorlist
[cachyos-core-v3]
Include = /etc/pacman.d/cachyos-v3-mirrorlist
[cachyos-extra-v3]
Include = /etc/pacman.d/cachyos-v3-mirrorlist
[cachyos]
Include = /etc/pacman.d/cachyos-mirrorlist

EOT
cat /etc/pacman.conf >> /etc/pacman.conf.new
mv /etc/pacman.conf.new /etc/pacman.conf
pacman -Sy --noconfirm paru

echo "=========================================="
echo " 5. APPLYING VERIFIED CONFIG SNIPPETS     "
echo "=========================================="

# TUIGREET CONFIG
echo "-> Configuring tuigreet..."
mkdir -p /etc/greetd
cat <<EOT > /etc/greetd/config.toml
[default_session]
command = "tuigreet --time --remember --theme 'border=white;text=white;prompt=white;time=red;action=magenta;button=black;container=black;input=magenta' --cmd start-hyprland"
user = "greeter"
EOT

# MKINITCPIO & PLYMOUTH
echo "-> Configuring mkinitcpio & plymouth..."
sed -i 's/Theme=.*$/Theme=colorful/' /etc/plymouth/plymouthd.conf
sed -i 's/useFirmwareBackground=.*$/useFirmwareBackground=false/' /etc/plymouth/plymouthd.conf
cat <<EOT > /etc/mkinitcpio.conf
MODULES=(f2fs i915)
BINARIES=(/usr/bin/f2fsck)
FILES=()
HOOKS=(base systemd sd-plymouth autodetect microcode modconf kms keyboard keymap sd-vconsole block filesystems fsck)
EOT
mkinitcpio -P

# SYSTEMD-BOOT CONFIG
echo "-> Installing and configuring systemd-boot..."
bootctl install
cat <<EOT > /boot/loader/loader.conf
timeout 3
console-mode max
default @saved
EOT

ROOT_UUID=$(blkid -s UUID -o value "$ROOT_DEV")
cat <<EOT > /boot/loader/entries/linux-cachyos.conf
title   Arch Linux (CachyOS-F2FS)
linux   /vmlinuz-linux-cachyos
initrd  /intel-ucode.img
initrd  /initramfs-linux-cachyos.img
options root=UUID=$ROOT_UUID rw rootflags=atgc compress_algorithm=zstd:6 quiet splash
EOT

echo "=========================================="
echo " 6. CLONING GIT REPO & ROUTING DOTFILES   "
echo "=========================================="
# Doing this as the user so permissions don't break!
sudo -u "$USERNAME" bash -c '
    mkdir -p ~/.config ~/Pictures
    git clone https://github.com/sszn4kev/arch.git /tmp/my-arch-dots
    cp -r /tmp/my-arch-dots/* ~/.config/
    mv ~/.config/wallpapers ~/Pictures/
    rm -rf /tmp/my-arch-dots
'

echo "=========================================="
echo " 7. PARU PACKAGE INSTALLATION             "
echo "=========================================="
# Define the list of AUR packages
PACKAGES=(
    linux-firmware-git
    linux-git
    hyprshot-git
    aquamarine-git
    bemoji-git
    brightnessctl-git
    catppuccin-cursors-mocha
    clipvault
    ffmpeg-git
    foot-git
    fuzzel-git
    greetd-git
    greetd-tuigreet-git
    haruna-git
    hyprcursor-git
    hyprgraphics-git
    hypridle-git
    hyprland-git
    hyprland-guiutils-git
    hyprland-protocols-git
    hyprland-qt-support-git
    hyprlang-git
    hyprlock-git
    hyprpaper-git
    hyprpicker-git
    hyprpolkitagent-git
    hyprqt6engine-git
    hyprtoolkit-git
    hyprutils-git
    hyprwayland-scanner-git
    hyprwire-git
    inotify-tools-git
    karchive-git
    kcodecs-git
    kconfig-git
    kdbusaddons-git
    kdoctools-git
    kglobalaccel-git
    ki18n-git
    kitemviews-git
    kwindowsystem-git
    libcava
    libfprint-tod
    libpipewire-git
    libwireplumber-git
    mpv-full-git
    pacman-contrib-git
    pipewire-alsa-git
    pipewire-git
    pipewire-pulse-git
    pipewire-x11-bell-git
    seatd-git
    solid-git
    sonnet-git
    tllist-git
    ttf-joypixels
    vivaldi-snapshot
    wallust-git
    waybar-git
    wireguard-tools-git
    wireplumber-git
    wl-clipboard-git
    wlogout-git
    xdg-desktop-portal-git
    xdg-desktop-portal-hyprland-git
)

echo "Starting installation of ${#PACKAGES[@]} packages..."
# Running paru as the user. Note: You will be asked for your sudo password here!
sudo -u "$USERNAME" paru -S --needed --noconfirm "${PACKAGES[@]}"

echo "=========================================="
echo " 8. ENABLING SERVICES                     "
echo "=========================================="
systemctl enable greetd

echo "=========================================="
echo " ✅ SYSTEM SETUP COMPLETE!                 "
echo " Type 'exit', 'umount -R /mnt', and reboot"
echo "=========================================="
