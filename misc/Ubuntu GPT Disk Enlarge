# First resize the disk in Proxmox

sudo fdisk -l    # should show which disks are there. Typically /dev/sda

*/
GPT PMBR size mismatch (167772159 != 314572799) will be corrected by write.
The backup GPT table is not on the end of the device. This problem will be corrected by write.
/*

sudo parted /dev/sda

(parted) print       # inside parted

# Warning: Not all of the space available to /dev/sda appears to be used, you can fix the GPT to use all of the space (an
# extra 146800640 blocks) or continue with the current setting?

Fix/Ignore? F

Disk Flags:

Number Start End Size File system Name Flags
14 1049kB 5243kB 4194kB bios_grub
15 5243kB 116MB 111MB fat32 boot, esp
1 116MB 85.9GB 85.8GB ext4

(parted) resizepart 1

Warning: Partition /dev/sda1 is being used. Are you sure you want to continue?
Yes/No? y

End? [85.9GB]? 100%

(parted) quit

sudo resize2fs /dev/sda1

df -h

sudo reboot
