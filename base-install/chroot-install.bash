#! /bin/bash

echo "Updaing mirrorlist"
reflector -c "India" -f 5 > /etc/pacman.d/mirrorlist

echo "Chrooted into Arch and Settin up base system"
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime  
hwclock --systohc 

echo "Setting locales"
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
locale-gen

echo "Adding persistent keymap"
echo "KEYMAP=us" > /etc/vconsole.conf

echo "Setting hosts and hostname"
echo "arch" >> /etc/hostname 
echo "127.0.0.1	localhost" >>etc/hosts
echo "::1	localhost" >>etc/hosts
echo "127.0.1.1	arch.localdomain arch" >>etc/hosts

echo "Setting default root passwd as password"
echo root:password | chpasswd

echo "Installing lot of softwares"
pacman -S --noconfirm intel-ucode linux-zen linux-zen-headers linux-firmware reflector btrfs-progs bridge-utils wpa_supplicant wireless_tools networkmanager nm-connection-editor network-manager-applet dhcpcd openssh git wget ntfs-3g reflector rsync nfs-utils inetutils dnsutils bluez bluez-utils cups hplip alsa-utils pulseaudio virt-manager libvirt qemu qemu-arch-extra dnsmasq neovim grub efibootmgr

# Insall Nvidia Drivers
# pacman -S --noconfirm nvidia-dkms nvidia-utils nvidia-settings

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
systemctl enable sshd
systemctl enable bluetooth
systemctl enable libvirtd
systemctl enable reflector.timer

echo "Updating sudo" 
pacman --noconfirm --sync sudo

echo "Adding user \"biswajit\" with default root and user password as password"
useradd -G wheel,power,audio,video,libvirt -d /home/biswajit -m biswajit
sed -i '0,/# %wheel/s// %wheel/' /etc/sudoers
echo biswajit:password | chpasswd

sleep 1s
echo "Exiting out of chroot"
sleep 1s
exit
