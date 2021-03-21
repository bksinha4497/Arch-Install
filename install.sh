#!/bin/bash

if [[ $(lsblk -d -o name) =~ "nvme" ]]
then
 DRIVE=/dev/nvme0n1
elif [[ $(lsblk -d -o name) =~ "sda" ]]
then
 DRIVE=/dev/sda
else
 DRIVE=/dev/vda
fi

swap_size="1"

echo "Wiping drive $DRIVE"
sgdisk --zap-all $DRIVE

echo "Partitioning drive with partition labels"
sgdisk --clear --new=1:0:+512MiB --typecode=1:ef00 --change-name=1:EFI --new=2:0:+"$swap_size"GiB --typecode=2:8200 --change-name=2:swap --new=3:0:0 --typecode=3:8300 --change-name=3:system $DRIVE

echo "Formatting EFI partition"
mkfs.fat -F32 -n EFI /dev/disk/by-partlabel/EFI

echo "Setting up swap"
mkswap -L swap /dev/mapper/swap
swapon -L swap

echo "Creating and mounting BTRFS subvolumes"
mkfs.btrfs --force --label system /dev/mapper/system
mount -t btrfs LABEL=system /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
umount -R /mnt
mkdir /mnt/home
mkdir /mnt/.snapshots
o=defaults,x-mount.mkdir
o_btrfs=$o,compress=zstd,ssd,noatime,autodefrag,rw,space_cache
mount -t btrfs -o subvol=@,$o_btrfs LABEL=system /mnt  
mount -t btrfs -o subvol=@home,$o_btrfs LABEL=system /mnt/home 
mount -t btrfs -o subvol=@snapshots,$o_btrfs LABEL=system /mnt/.snapshots 

echo "installing arch base"
pacstrap /mnt base linux-zen linux-firmware intel-ucode base-devel 
genfstab -U /mnt >> /mnt/etc/fstab  
arch-chroot /mnt << EOF

echo "Chrooted into Arch and Settin up base system"
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

echo "Installing lot of softwares"
pacman -S --no-confirm bridge-utils wpa_supplicant wireless_tools networkmanager nm-connection-editor network-manager-applet dhcpcd  openssh nmctl git wget firewalld vim ntfs-3g terminus-font reflector rsync nfs-utils inetutils dnsutils bluez bluez-utils cups hplip alsa-utils pulseaudio bash-completion acpi acpi_call tlp cockpit cockpit-machines qemu qemu-arch-extra ovmf dnsmasq nvim grub efibootmgr

echo "Generating initramfs"
mkinitcpio -P 

echo "Making /boot/efi and mounting EFI partition"
mkdir /boot/efi
mount LABEL=EFI /boot/efii

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
systemctl enable firewalld
systemctl enable sshd
systemctl enable bluetooth
systemctl enable libvirtd
systemctl enable avahi-daemon
systemctl enable tlp
systemctl enable reflector.timer
systemctl enable acpid

echo "Adding user bksinhs4497 with default root and user password as password"
useradd -G wheel,power,audio,video -m bksinha4497
usermod -aG libvirt bksinha4497
sed -i '/82/s/.//' /etc/sudoers
echo bksinha4497:password | chpasswd

echo "Exiting and revbooting in 5...4...3..2..1."
sleep 5s
exit
umount -R /mnt
reboot
