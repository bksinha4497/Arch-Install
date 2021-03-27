#! /bin/bash

echo "Chrooted into Arch and Settin up base system"
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime  
hwclock --systohc 

echo "Setting locales"
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
locale-gen

echo "Setting hosts and hostname"
echo "arch" >> /etc/hostname 
echo "127.0.0.1	localhost" >>etc/hosts
echo "::1	localhost" >>etc/hosts
echo "127.0.1.1	arch.localdomain arch" >>etc/hosts

echo "Setting default root passwd as password"
echo root:password | chpasswd

echo "Installing lot of softwares"
pacman -S --noconfirm btrfs-progs bridge-utils wpa_supplicant wireless_tools networkmanager nm-connection-editor network-manager-applet dhcpcd  openssh git wget ufw vim ntfs-3g terminus-font reflector rsync nfs-utils inetutils dnsutils bluez bluez-utils cups hplip alsa-utils pulseaudio bash-completion acpi acpi_call tlp cockpit cockpit-machines qemu qemu-arch-extra ovmf dnsmasq vim grub efibootmgr acpid

# Insall Nvidia Drivers
# pacman -S --noconfirm nvidia nvidia-utils nvidia-settings

# Install Optimus for hybrid graphics 
# pacman -S optimus-manager

echo "Generating initramfs"
mkinitcpio -P 

echo "Making /boot/efi and mounting EFI partition"
mkdir /boot/efi
mount LABEL=EFI /boot/efi

echo "Installing Grub"
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB  
grub-mkconfig -o /boot/grub/grub.cfg

echo "Setting up grub boot loader to run startup.nsh file correctly during boot"
mkdir /boot/efi/EFI/BOOT
cp /boot/efi/EFI/GRUB/grubx64.efi /boot/efi/EFI/BOOT/BOOTx64.EFI
echo "bcf boot add 1 fs0:\EFI\GRUB\grubx64.efi "GRUB BOOT LOADER"" >>/boot/efi/startup.nsh

echo "Enabelling services to start on boot"
systemctl enable NetworkManager 
systemctl enable dhcpcd
systemctl enable ufw
systemctl enable sshd
systemctl enable bluetooth
systemctl enable libvirtd
systemctl enable avahi-daemon
systemctl enable tlp
systemctl enable reflector.timer
systemctl enable acpid

echo "Updating sudo" 
pacman --sync sudo

echo "Adding user \"biswajit\" with default root and user password as password"
usermod -aG wheel,power,audio,video,libvirt biswajit
sed -i '0,/# %wheel/s// %wheel/' /etc/sudoers
echo biswajit:password | chpasswd

sleep 1s
echo "Exiting out of chroot"
sleep 1s
exit
