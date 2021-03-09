# Arch Installation with btrfs
## Partitions
`cfdisk`
1. Parition number 1 : 512m , Type = EFI
2. Partiton number 2 : 1G , Type = Linux Swap
3. partiton number 3 : 20G , Type = Linux File System
## Formatting the partitons
```
mkfs.fat -F32 /dev/vda1`  <!-- making first partiton as fat 32 to mount to /boot/efi for uefi mode -->
mkswap /dev/vda2 <!-- making second partiton as swap -->
swapon /dev/vda2 <!-- sayling system to start using this  partition for swap -->
mkfs.btrfs /dev/vda3 <!-- formatting this partiton os btrfs and create subvolumes inside this -->
mount -t btrfs /dev/vda3 /mnt <!-- mount /mnt to btrfs drive to create subvolumes -->
btrfs subvolume create /mnt/root
btrfs subvolume create /mnt/home
btrfs subvolume create /mnt/snapshots
umount -R /mnt <!-- unmount  /mnt to btrfs drive after creating subvolumes -->
mkdir /mnt/home
mkdir /mnt/.snapshots
mount -t btrfs -o subvol=root,compress=zstd,ssd,noatime,autodefrag,rw,space_cache /dev/vda3 /mnt  <!-- mount sub volumes :- mounting root sub volume -->
mount -t btrfs -o subvol=home,compress=zstd,ssd,noatime,autodefrag,rw,space_cache /dev/vda3 /mnt/home <!-- mount sub home :- mounting root sub volume -->
mount -t btrfs -o subvol=snapshots,compress=zstd,ssd,noatime,autodefrag,rw,space_cache /dev/vda3 /mnt/.snapshots <!-- mount sub volumes :- snapshots root sub volume -->
pacstrap /mnt base linux-zen linux-firmware intel-ucode base-devel wpa_supplicant wireless_tools networkmanager nm-connection-editor network-manager-applet vim grub efibootmgr dhcpcd networkmanager openssh nmctl git wget <!-- install base system-->
genfstab -U /mnt >> /mnt/etc/fstab  <!-- generate fstal for auto mounting drives / subvolumes -->
arch-chroot /mnt <!-- login to installed system -->
```
## Base system is installed now we set time zone , keyboard layout , hostname and hosts
```
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc
vim /etc/locale.gen
LANG=en_US.UTF-8
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf
echo arch > /etc/hostname
vim /etc/hosts
127.0.0.1	localhost
::1		localhost
127.0.1.1	arch.localdomain	arch
passwd
mkinitcpio -P
systemctl enable NetworkManager
systemctl enable dhcpcd
```
## Setup boot manager with grub
```
mkdir /boot/efi
mount /dev/vda1 /boot/efi
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB  <!-- install bootloader and configure-->
grub-mkconfig -o /boot/grub/grub.cfg
```

## additional important step  UEFI bootloader (Mainly to run in vm)
<!-- if EFI partiton is mounted at /boot/efi -->
mkdir /boot/efi/EFI/BOOT
cp /boot/efi/EFI/GRUB/grubx64.efi /boot/efi/EFI/BOOT/BOOTx64.EFI
vim /boot/efi/startup.nsh
bcf boot add 1 fs0:\EFI\GRUB\grubx64.efi "GRUB BOOT LOADER"

exit
umount -R /mnt
reboot

## POST INSTALLATION
1. install vi : pacman -S vi
2. instll / update sudo :  pacman --sync sudo
3. enable multilib : vim /etc/pacman.conf
4. Add users
	useradd -G wheel,power,audio,video -m bksinha4497
	passwd bksinha4497
5. edit sudoers file : visudo
	## Uncomment to allow members of group wheel to execute any command
	%wheel ALL=(ALL) ALL
## Addition Commands

1. Check system running on wayland or xorg : echo $XDG_SESSION_TYPE

## GNOME with Arch

`pacman -S wayland gnome gnome-extras xf86-video-intel`

## How to install NVIDIA video driver on Arch Linux 

`sudo pacman -S nvidia cuda nvidia-settings`

## How to install and use Bumblebee (how to enable NVIDIA Optimus on Arch Linux)

```
sudo pacman -S bumblebee virtualgl bbswitch acpid mesa
sudo systemctl enable bumblebeed.service
sudo systemctl enable acpid.service
sudo usermod -a -G bumblebee $USER
```

## System freezes after installing Bumblebee

`lspci -k`

If the system freezes completely, reboot and remove the bbswitch package.

`sudo pacman -R bbswitch`

## How to use Bumblebee / NVIDIA Optimus on Linux

`optirun PROGRAM`

## Pacman hook
###### To avoid the possibility of forgetting to update initramfs after an NVIDIA driver upgrade, you may want to use a pacman hook:

`vim /etc/pacman.d/hooks/nvidia.hook`
```
[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Package
Target=nvidia
Target=linux-zen
# Change the linux-zen part above and in the Exec line if a different kernel is used
# Make sure the Target package set in this hook is the one you've installed in steps above (e.g. nvidia, nvidia-dkms, nvidia-lts or nvidia-ck-something).

[Action]
Description=Update Nvidia module in initcpio
Depends=mkinitcpio
When=PostTransaction
NeedsTargets
Exec=/bin/sh -c 'while read -r trg; do case $trg in linux) exit 0; esac; done; /usr/bin/mkinitcpio -P'
```
