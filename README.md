# Arch Installation with btrfs
## Partitions
`Simple Setup for Virtual Machine`
1. Parition number 1 : 512M , Type = EFI
2. Partiton number 2 : 1G   , Type = Linux Swap
3. partiton number 3 : 20G  , Type = Linux File System

## Install base system
1. Clone this repo into your booted arch iso using `git clone https://github.com/bksinha4497/Arch-Install`
2. CD into the directory `cd Arch-Install/base-install`
3. Make the scripts executable using `chmod u+x base-install.bash chroot-install.bash`
4. To install nvidia drivers uncomment lines below # Nvidia 
  [Arch-Nvidia](https://wiki.archlinux.org/index.php/NVIDIA#Installation)
5. Optionally you can install Optimus-Manager to manage hybrid graphics by uncommenting lines below # Install Optimus 
  [Optimus-Manager](https://github.com/Askannz/optimus-manager)
6. Default users are root and biswajit and password is "password" 
7. You can edit chroot-install.bash and at the end of the file change the user name and password as per you need.
8. Execute the script to start installation using `./base-install.bash`
9. After Installation you can reboot use the system as it as a Arch Server or you can choose to install kde desktop or gnome desktop via script
  [desktop-env-install.bash](https://github.com/bksinha4497/Arch-Install/blob/main/desktop-env-install.bash)

## Addition Commands

1. Check system running on wayland or xorg : echo $XDG_SESSION_TYPE

## For MSI laptops keyboard to have lighting

##### Refer below : 

[MSI PER KEY RGB](https://github.com/bksinha4497/msi-perkeyrgb)

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
