#! /bin/bash

# Function to handle errors
handle_error() {
    echo "Error on line $1"
    exit 1
}

# Trap errors
trap 'handle_error $LINENO' ERR

echo "Chrooted into Arch and Setting up base system"
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime  
hwclock --systohc 

echo "Setting locales"
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
locale-gen

echo "Adding persistent keymap"
echo "KEYMAP=us" > /etc/vconsole.conf

echo "Setting hosts and hostname"
echo "arch" > /etc/hostname 
cat <<EOF > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   arch.localdomain arch
EOF

echo "Setting default root passwd as password"
echo root:password | chpasswd

echo "Installing lot of software"
pacman -Sy --noconfirm intel-ucode xf86-video-intel reflector btrfs-progs snapper snap-pac grub efibootmgr grub-btrfs bridge-utils wpa_supplicant wireless_tools networkmanager nm-connection-editor network-manager-applet dhcpcd openssh wget git ntfs-3g exfat-utils reflector rsync nfs-utils inetutils dnsutils bluez bluez-utils alsa-utils pipewire gst-plugin-pipewire pipewire-pulse pipewire-alsa pipewire-jack virt-manager libvirt qemu qemu-arch-extra ovmf dnsmasq vim neofetch ghostscript libreoffice-fresh vlc zsh

# Install Nvidia Drivers (uncomment if needed)
#echo "Installing nvidia drivers"
#pacman -S --noconfirm nvidia-dkms nvidia-utils nvidia-settings nvidia-prime

echo "Generating initramfs"
mkinitcpio -P 

echo "Creating directory /boot/efi and Mounting EFI partition to /boot/efi"
mkdir /boot/efi
mount LABEL=EFI /boot/efi

echo "Installing Grub"
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --recheck
grub-mkconfig -o /boot/grub/grub.cfg

echo "Enabling services to start on boot"
systemctl enable NetworkManager 
systemctl enable dhcpcd
systemctl enable sshd
systemctl enable bluetooth
systemctl enable libvirtd
systemctl enable reflector.timer
systemctl enable grub-btrfs.path
#systemctl enable optimus-manager

echo "Updating sudo" 
pacman --noconfirm --sync sudo

echo "Adding user \"biswajit\" with default root and user password as password"
useradd -G wheel,power,audio,video,storage,libvirt,kvm,cups -d /home/biswajit -m biswajit
sed -i '0,/# %wheel/s// %wheel/' /etc/sudoers
echo biswajit:password | chpasswd

echo "Updating zsh as default shell"
chsh -s /usr/bin/zsh
chsh -s /usr/bin/zsh biswajit

echo "Updating mirrorlist"
reflector -c "India" -f 5 > /etc/pacman.d/mirrorlist

#echo "Adding Nvidia Hook"
#cp /Arch-Install/nvidia.hook /etc/pacman.d/hooks/

echo "Adding grub hook - run grub-mkconfig when new linux kernel is installed or updated or removed"
cp /Arch-Install/grub.hook /usr/share/libalpm/hooks/

echo "Creating snapper config"
snapper -c root create-config /

sleep 1s
echo "Exiting out of chroot"
sleep 1s
exit

