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
pacman -Sy --noconfirm intel-ucode xf86-video-intel reflector btrfs-progs snapper snap-pac grub efibootmgr grub-btrfs bridge-utils wpa_supplicant wireless_tools networkmanager nm-connection-editor network-manager-applet dhcpcd openssh wget git ntfs-3g reflector rsync nfs-utils inetutils dnsutils bluez bluez-utils cups cups-pdf hplip alsa-utils pipewire gst-plugin-pipewire pipewire-pulse pipewire-alsa pipewire-jack easyeffects virt-manager libvirt qemu qemu-arch-extra ovmf dnsmasq neovim fish neofetch

# Insall Nvidia Drivers
#echo "Installing nvdia drivers"
#pacman -S --noconfirm nvidia-dkms nvidia-utils nvidia-settings

# Install Optimus for hybrid graphics
#pacman -Sy optimus-manager optimus-manager-qt bbswitch-dkms-git

echo "Generating initramfs"
mkinitcpio -P 

echo "Creating directory /boot/efi and Mounting EFI partition to /boot/efi"
mkdir /boot/efi
mount LABEL=EFI /boot/efi

echo "Installing Grub"
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --recheck
grub-mkconfig -o /boot/grub/grub.cfg

echo "Enabelling services to start on boot"
systemctl enable NetworkManager 
systemctl enable dhcpcd
systemctl enable sshd
systemctl enable bluetooth
systemctl enable libvirtd
systemctl enable reflector.timer
systemctl enable grub-btrfs.path
systemctl enable cups
#systemctl enable optimus-manager

echo "Updating sudo" 
pacman --noconfirm --sync sudo

echo "Adding user \"biswajit\" with default root and user password as password"
useradd -G wheel,power,audio,video,storage,libvirt,kvm,cups -d /home/biswajit -m biswajit
sed -i '0,/# %wheel/s// %wheel/' /etc/sudoers
echo biswajit:password | chpasswd

echo "Updating fish as default shell"
chsh -s /usr/bin/fish
chsh -s /usr/bin/fish biswajit

echo "Updaing mirrorlist"
reflector -c "India" -f 5 > /etc/pacman.d/mirrorlist

#echo "Adding Nvidia Hook"
#cp /Arch-Install/nvidia.hook /etc/pacman.d/hooks/

#echo "Adding optimus manager configuration"
#cp /Arch-Install/optimus-manager.conf /etc/optimus-manager/

echo "Adding grub hook - run grub0-mkconfig when new linux kernel is insralled or updated or removed"
cp /Arch-Install/grub.hook /usr/share/libalpm/hooks/

echo "Creating snapper config"
snapper -c root create-config /

sleep 1s
echo "Exiting out of chroot"
sleep 1s
exit
