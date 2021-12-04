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
sgdisk --clear --new=1:0:+512MiB --typecode=1:ef00 --change-name=1:efi --new=2:0:0 --typecode=2:8300 --change-name=2:system $DRIVE

sleep 1s

echo "Formatting EFI partition"
mkfs.fat -F32 -n EFI /dev/disk/by-partlabel/efi

echo "Creating  subvolumes"
mkfs.btrfs --force --label system /dev/disk/by-partlabel/system
mount -t btrfs LABEL=system /mnt

btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@root
btrfs subvolume create /mnt/@srv
btrfs subvolume create /mnt/@cache
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@tmp
btrfs subvolume create /mnt/@snapshots

umount -R /mnt

sleep 1

mkdir /mnt/{boot,home,root,srv,var,var/cache,var/log,var/tmp,.snapshots}

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
mount -t btrfs -o subvol=@snapshots,$o_btrfs LABEL=system /mnt/.snapshots 

echo "Installing arch base"
pacstrap /mnt base base-devel linux-zen linux-zen-headers linux-firmware

echo "Generating fstab"
genfstab -U /mnt >> /mnt/etc/fstab  

echo "chrooting into arch installed system"
cp -r ~/Arch-Install /mnt/
chmod u+x /mnt/Arch-Install/base-install/*
arch-chroot /mnt ./Arch-Install/base-install/chroot-install.bash

umount -R /mnt

if mount | grep /mnt > /dev/null; then
    echo "Please unmount /mnt using :: unmount -R /mnt and reboot"
else
    echo "You can now reboot the machine"
fi
