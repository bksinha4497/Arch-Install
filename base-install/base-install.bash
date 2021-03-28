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
sgdisk --clear --new=1:0:+512MiB --typecode=1:ef00 --change-name=1:efi --new=2:0:+"$swap_size"GiB --typecode=2:8200 --change-name=2:swap --new=3:0:0 --typecode=3:8300 --change-name=3:system $DRIVE

sleep 1s

echo "Formatting EFI partition"
mkfs.fat -F32 -n EFI /dev/disk/by-partlabel/efi

echo "Setting up swap"
mkswap -L swap /dev/disk/by-partlabel/swap
swapon -L swap

echo "Creating  subvolumes"
mkfs.btrfs --force --label system /dev/disk/by-partlabel/system
mount -t btrfs LABEL=system /mnt

if mount | grep /mnt > /dev/null; then
    echo "/mnt mounted"
else
    echo "/mnt is not mounted"
fi

btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@root
btrfs subvolume create /mnt/@srv
btrfs subvolume create /mnt/@cache
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@tmp

umount -R /mnt


mkdir /mnt/home
mkdir /mnt/root
mkdir /mnt/srv
mkdir /mnt/var
mkdir /mnt/var/cache
mkdir /mnt/var/log
mkdir /mnt/var/tmp

echo "Mounting BTRFS subvolumes"
o=defaults,x-mount.mkdir
o_btrfs=$o,compress=zstd,ssd,noatime,autodefrag,rw,space_cache
mount -t btrfs -o subvol=@,$o_btrfs LABEL=system /mnt  
mount -t btrfs -o subvol=@home,$o_btrfs LABEL=system /mnt/home 
mount -t btrfs -o subvol=@root,$o_btrfs LABEL=system /mnt/root 
mount -t btrfs -o subvol=@srv,$o_btrfs LABEL=system /mnt/srv 
mount -t btrfs -o subvol=@cache,$o_btrfs LABEL=system /mnt/var/cache 
mount -t btrfs -o subvol=@log,$o_btrfs LABEL=system /mnt/var/log 
mount -t btrfs -o subvol=@tmp,$o_btrfs LABEL=system /mnt/var/tmp 

sleep 3s

echo "installing arch base"
pacstrap /mnt base linux-zen linux-firmware intel-ucode base-devel 
genfstab -U /mnt >> /mnt/etc/fstab  

echo "chrooting into arch installed system"
cp ~/Arch-Install/base-install/chroot-install.bash /mnt/@/
chmod u+x /mnt/@/chroot-install.bash
arch-chroot /mnt ./@/chroot-install.bash

umount -R /mnt
echo "You can now reboot the machine"
#reboot
