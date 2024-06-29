#!/bin/bash

# Function to handle errors
handle_error() {
    echo "Error on line $1"
    exit 1
}

# Trap errors
trap 'handle_error $LINENO' ERR

echo "Chrooted into Arch and Setting up base system"

# Set timezone
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime  
hwclock --systohc 

# Set locales
echo "Setting locales"
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
locale-gen

# Set keymap
echo "Adding persistent keymap"
echo "KEYMAP=us" > /etc/vconsole.conf

# Set hostname and hosts file
echo "Setting hosts and hostname"
echo "arch" > /etc/hostname 
cat <<EOF > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   arch.localdomain arch
EOF

# Set root password
echo "Setting default root password"
echo root:password | chpasswd

# Install necessary software packages
echo "Installing necessary software"
pacman -Sy --noconfirm \
    intel-ucode \
    xf86-video-intel \
    reflector \
    btrfs-progs \
    snapper \
    snap-pac \
    grub \
    efibootmgr \
    grub-btrfs \
    inotify-tools \
    bridge-utils \
    wpa_supplicant \
    wireless_tools \
    networkmanager \
    nm-connection-editor \
    network-manager-applet \
    dhcpcd \
    openssh \
    wget \
    git \
    ntfs-3g \
    exfat-utils \
    reflector \
    rsync \
    nfs-utils \
    inetutils \
    dnsutils \
    bluez \
    bluez-utils \
    alsa-utils \
    pipewire \
    gst-plugin-pipewire \
    pipewire-pulse \
    pipewire-alsa \
    pipewire-jack \
    virt-manager \
    libvirt \
    qemu-full \
    ovmf \
    dnsmasq \
    vim \
    fastfetch \
    ghostscript \
    libreoffice-fresh \
    vlc \
    zsh

# Optionally install Nvidia drivers
#echo "Installing nvidia drivers"
#pacman -S --noconfirm nvidia-dkms nvidia-utils nvidia-settings nvidia-prime

# Generate initramfs
echo "Generating initramfs"
mkinitcpio -P 

# Mount EFI partition
echo "Creating directory /boot/efi and mounting EFI partition"
mkdir -p /boot/efi
mount LABEL=EFI /boot/efi

# Install Grub bootloader
echo "Installing Grub bootloader"
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --recheck
grub-mkconfig -o /boot/grub/grub.cfg

# Enable services to start on boot
echo "Enabling services to start on boot"
systemctl enable NetworkManager 
systemctl enable dhcpcd
systemctl enable sshd
systemctl enable bluetooth
systemctl enable libvirtd
systemctl enable reflector.timer
systemctl enable grub-btrfsd.service
# systemctl enable optimus-manager (uncomment if needed)

# Update sudoers
echo "Updating sudo"
pacman --noconfirm --sync sudo

# Add a user and set permissions
echo "Adding user 'biswajit' and setting permissions"
useradd -G wheel,power,audio,video,storage,libvirt,kvm -m biswajit
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
echo "biswajit:password" | chpasswd

# Set zsh as default shell for the user
echo "Setting zsh as default shell for user 'biswajit'"
chsh -s /usr/bin/zsh biswajit

# Update mirrorlist
echo "Updating mirrorlist"
reflector -c "India" -f 5 > /etc/pacman.d/mirrorlist

# Optionally add Nvidia hook
#cp /Arch-Install/nvidia.hook /etc/pacman.d/hooks/

# Add grub hook for kernel updates
echo "Adding grub hook for kernel updates"
cp /Arch-Install/grub.hook /usr/share/libalpm/hooks/

# Create snapper configuration
echo "Creating snapper config"
snapper -c root create-config /

# Exit chroot environment
echo "Exiting chroot environment"
exit
