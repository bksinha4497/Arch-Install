#! /bin/bash

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
pacman -Sy --noconfirm intel-ucode xf86-video-intel linux-firmware reflector btrfs-progs snapper snap-pac grub efibootmgr grub-btrfs bridge-utils wpa_supplicant wireless_tools networkmanager nm-connection-editor network-manager-applet dhcpcd openssh wget git ntfs-3g reflector rsync nfs-utils inetutils dnsutils bluez bluez-utils cups hplip alsa-utils pipewire gst-plugin-pipewire pipewire-pulse pipewire-alsa pipewire-jack pulseeffects virt-manager libvirt qemu qemu-arch-extra dnsmasq neovim

# Insall Nvidia Drivers
echo "Installing nvdia drivers"
pacman -S --noconfirm nvidia-dkms nvidia-utils nvidia-settings

# Install Optimus for hybrid graphics
echo "Installing optimus manager for hybrid graphics"
wget https://aur.archlinux.org/cgit/aur.git/snapshot/optimus-manager.tar.gz
wget https://aur.archlinux.org/cgit/aur.git/snapshot/optimus-manager-qt.tar.gz
wget https://aur.archlinux.org/cgit/aur.git/snapshot/bbswitch-dkms-git.tar.gz
pacman -U optimus-manager-tar.gz optimus-manager-qt.tar.gz bbswitch-dkms-git.tar.gz

echo "Generating initramfs"
mkinitcpio -P 

echo "Making /boot/efi and mounting EFI partition"
mkdir /boot/efi
mount LABEL=EFI /boot/efi

echo "Installing Grub"
grub-install --target=x86_64-efi --efi-directory=/boot/efi --removable --boot-directory=/boot/efi/EFI --bootloader-id=grub
grub-mkconfig -o /boot/efi/EFI/grub/grub.cfg

#echo "Setting up grub boot loader to run startup.nsh file correctly during boot"
#mkdir /boot/efi/EFI/BOOT
#cp /boot/efi/EFI/GRUB/grubx64.efi /boot/efi/EFI/BOOT/BOOTx64.EFI
#echo "bcf boot add 1 fs0:\EFI\GRUB\grubx64.efi "GRUB BOOT LOADER"" >>/boot/efi/startup.nsh

echo "Enabelling services to start on boot"
systemctl enable NetworkManager 
systemctl enable dhcpcd
systemctl enable sshd
systemctl enable bluetooth
systemctl enable libvirtd
systemctl enable reflector.timer
systemctl enable grub-btrfs.path
systemctl enable optimus-manager

echo "Updating sudo" 
pacman --noconfirm --sync sudo

echo "Adding user \"biswajit\" with default root and user password as password"
useradd -G wheel,power,audio,video,libvirt,kvm,cups -d /home/biswajit -m biswajit
sed -i '0,/# %wheel/s// %wheel/' /etc/sudoers
echo biswajit:password | chpasswd

echo "Updaing mirrorlist"
reflector -c "India" -f 5 > /etc/pacman.d/mirrorlist

echo "Adding Nvidia Hook"
cp /Arch-Install/nvidia.hook /etc/pacman.d/hooks/

echo "Adding optimus manager configuration"
cp /Arch-Install/optimus-manager.conf /etc/optimus-manager/

echo "Adding gub hook - run grub0-mkconfig when new linux kernel is insralled or updated or removed"
cp /Arch-Install/grub.hook /usr/share/libalpm/hooks/

echo "Creating snapper config"
snapper -c root create-config /


sleep 1s
echo "Exiting out of chroot"
sleep 1s
exit
