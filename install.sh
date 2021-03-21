#!/bin/bash

pacstrap /mnt base linux-zen linux-firmware intel-ucode base-devel 
genfstab -U /mnt >> /mnt/etc/fstab  
arch-chroot /mnt

ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime  
hwclock --systohc 
echo "LANG=en_US.UTF-8" >>/etc/locale.gen 
locale-gen 
echo "en_US.UTF-8" >> /etc/locale.conf
echo "en_IN UTF-8" >> /etc/locale.conf
echo "arch" >> /etc/hostname 
echo "127.0.0.1	localhost" >>etc/hosts
echo "::1	localhost" >>etc/hosts
echo "127.0.1.1	arch.localdomain arch" >>etc/hosts
echo root:password | chpasswd

pacman -S --no-confirm bridge-utils wpa_supplicant wireless_tools networkmanager nm-connection-editor network-manager-applet dhcpcd  openssh nmctl git wget firewalld vim ntfs-3g terminus-font reflector rsync nfs-utils inetutils dnsutils bluez bluez-utils cups hplip alsa-utils pulseaudio bash-completion acpi acpi_call tlp cockpit cockpit-machines qemu qemu-arch-extra ovmf dnsmasq nvim grub efibootmgr

# pacman -S --noconfirm xf86-video-amdgpu
# pacman -S --noconfirm nvidia nvidia-utils nvidia-settings

grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable cups
systemctl enable sshd
systemctl enable avahi-daemon
systemctl enable tlp
systemctl enable reflector.timer
systemctl enable fstrim.timer
systemctl enable libvirtd
systemctl enable firewalld
systemctl enable acpid

useradd -m ermanno
echo ermanno:password | chpasswd
usermod -aG libvirt ermanno

echo "ermanno ALL=(ALL) ALL" >> /etc/sudoers.d/ermanno


/bin/echo -e "\e[1;32mDone! Type exit, umount -a and reboot.\e[0m"


#pacman -S --no-confirm nvidia nvidia-settings nvidia-utils
#pacman -S --no-confirm nvidia xf86-video-amdgpu

mkinitcpio -P 

mkdir /boot/efi
mount /dev/vda1 /boot/efi
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB  
grub-mkconfig -o /boot/grub/grub.cfg

mkdir /boot/efi/EFI/BOOT
cp /boot/efi/EFI/GRUB/grubx64.efi /boot/efi/EFI/BOOT/BOOTx64.EFI
echo "bcf boot add 1 fs0:\EFI\GRUB\grubx64.efi "GRUB BOOT LOADER"" >>/boot/efi/startup.nsh

systemctl enable NetworkManager 
systemctl enable dhcpcd
systemctl enable firewalld
systemctl enable sshd
systemctl enable bluetooth
systemctl enable libvirtd
systemctl enable avahi-daemon
systemctl enable tlp
systemctl enable reflector.timer
systemctl enable acpid

useradd -G wheel,power,audio,video -m bksinha4497
usermod -aG libvirt bksinha4497
echo bksinha4497:password | chpasswd

exit
umount -R /mnt
reboot
