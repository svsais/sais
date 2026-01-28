echo "-------------------------------------"
echo "Welcome to Saki's Arch Installer v2.0"
echo "-------------------------------------"
printf 'Begin installation? (Y/n): '
read qtmp
if [[ $qtmp = "n" || $qtmp = "N" ]]; then
	exit
fi
echo "Initializing install..."
#init vars
disk_count=0
q_ssh="n"
q_reflector="n"
#colours
noformat="\033[0m"
font="\033[38;5;"
bgr="\033[48;5;"
pink="13m"
green="2m"
lime="10m"
navy="4m"
teal="6m"
aqua="14m"
white="15m"
red="9m"
dred="1m"
olive="3m"
#utility functions
slog () {
	echo "$font$olive[SAIS](Logger) -> $1$noformat"
}
sbegin () {
	sLog "$font$teal$1...$noformat"
}
sdone () {
	sLog "$font${teal}done.$noformat"
}
qyn () {
	if [ $2 = "y" ]; then
		printf "$font$green$1? (Y/n):$noformat "
	else
		printf "$font$green$1? (y/N):$noformat "
	fi
}
qdrive () {
	printf "$font$green$1:$noformat /dev/"
}
qstr () {
	printf "$font$green$1:$noformat "
}
sdone
clear
#install
slog "Install started."
lsblk
qdrive "Enter primary drive"
read primary_drive
qyn "Shred drive (replaces all data with random bits)" "n"
read qtmp
if [[ $qtmp = "y" || $qtmp = "Y" ]]; then
	sbegin "Shredding primary drive"
	shred -vn 1 /dev/$primary_drive
	sdone
fi
sbegin "Wiping primary drive"
sfdisk -w /dev/$primary_drive
sdone
sbegin "Partitioning primary drive"
qstr "Enter swap size bytes (default=32G)"
read qtmp
if [ qtmp = "" ]; then
	qtmp = "32G"
fi
echo -e "label: gpt\n size=1G, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B\n size=$qtmp, type=S\n size=+, type=4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709\n" | sfdisk /dev/$primary_drive
sdone
sbegin "Formatting primary drive partitions"
mkfs.fat -F 32 /dev/${primary_drive}1
mkswap /dev/${primary_drive}2
mkfs.ext4 /dev/${primary_drive}3
sdone
sbegin "Mounting primary drive partitions"
mount /dev/$root_partition /mnt
mount --mkdir /dev/$efi_partition /mnt/boot
sdone
sbegin "Enabling swap"
swapon /dev/$swap_partition
sdone
sbegin "Refreshing mirrors"
reflector_country = `curl https://ipapi.co/country`
reflector -p https -c $reflector_country -l 5 --sort rate --save /etc/pacman.d/mirrorlist
sdone
sbegin "Installing essential packages"
pacstrap -K /mnt base linux linux-firmware efibootmgr grub networkmanager sudo
sdone
sbegin "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab
sdone
sbegin "Fetching secondary install script"
curl "https://sakivali.github.io/Arch-Install-Guide/chroot.sh" > /mnt/tmp.sh
sdone
sbegin "Making secondary script runnable"
chmod a+x /mnt/tmp.sh
sdone
sbegin "Removing self"
rm -rf /tmp.sh
sdone
slog "Launching secondary script in arch-chroot."
arch-chroot /mnt /tmp.sh