echo "-------------------------------------"
echo "Welcome to Saki's Arch Installer v2.0"
echo "-------------------------------------"
printf 'Begin installation? (Y/n): '
read qtmp
if [[ $qtmp = "n" || $qtmp = "N" ]]; then
	exit
fi
echo "Initializing installer..."
#init vars
sdrive_count=0
sdrive_ids=()
sdrive_names=()
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
blue="12m"
teal="6m"
aqua="14m"
white="15m"
red="9m"
dred="1m"
olive="3m"
gray="8m"
purple="5m"
yellow="11m"
#utility functions
slog () {
	echo "$font$olive[SAIS](Logger) -> $1$noformat"
}
sbegin () {
	slog "$font$teal$1...$noformat"
}
sdone () {
	slog "$font${teal}done.$noformat"
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
#Query User for Install - Query first + Install later allows me to walk away while it installs
slog "Configuring install."
lsblk
qdrive "Enter primary drive"
read primary_drive
qstr "Enter swap size bytes (default=32G)"
read swap_size
if [ swap_size = "" ]; then
	swap_size="32G"
fi
#sec
qyn "Add secondary drive" "n"
read ltmp
while [[ $ltmp = "y" || $ltmp = "Y" ]]; do
	((sdrive_count=sdrive_count+1))
	lsblk
	drive "Enter secondary drive"
	read qtmp
	sdrive_ids+=("$qtmp")
	qstr "Name secondary drive (default=drive$sdrive_count)"
	read qtmp
	if [ qtmp = "" ]; then
		qtmp="drive$sdrive_count"
	fi
	sdrive_names+=("$qtmp")
	slog "Drive added."
	qyn "Add another secondary drive" "n"
	read ltmp
done
qyn "Shred drives (replaces all data with random bits)" "n"
read sh_drives
if [[ $sh_drives = "y" || $sh_drives = "Y" ]]; then
slog "Drives marked for shredding."
fi
# Package Selection UI
pkgui_packages=("yay" "git" "base-devel" "wget" "vim" "nano")
pkgui_selected=("" "" "" "" "" "")
pkgui_line_width=$(tput cols)
pkgui_line_width=$((pkgui_line_width/16))
pkguirender () {
	qrow=1
	for i in ${!pkgui_packages[@]}; do
		qtmp=${pkgui_packages[$i]}
		if [ $((i+1)) -gt $((pkgui_line_width*qrow)) ]; then
			printf '\n'
			((qrow=qrow+1))
		fi
		if [ $i -eq $1 ]; then
			if [[ ${pkgui_selected[$i]} = "" ]]; then
				printf "$font$aqua$bgr$gray%14s$noformat  " $qtmp
			else
				printf "$font$aqua$bgr$teal%14s$noformat  " $qtmp
			fi
		else
			if [[ ${pkgui_selected[$i]} = "" ]]; then
				printf "$font$white%14s$noformat  " $qtmp
			else
				printf "$font$white$bgr$purple%14s$noformat  " $qtmp
			fi
		fi
	done
	qtmp="Install"
	if [ ${#array[@]} -eq $1 ]; then
		printf '\n'
		printf "$font$yellow$bgr$dred%-14s$noformat  " $qtmp
	else
		printf '\n'
		printf "$font$yellow$bgr$dred%-14s$noformat  " $qtmp
		printf '\n'
	fi
}


#Install
slog "Starting install."
#Drives and Partitions
slog "Prepping drives."

if [[ $sh_drives = "y" || $sh_drives = "Y" ]]; then
	sbegin "Shredding primary drive"
	shred -vn 1 /dev/$primary_drive
	sdone
	if [sdrive_count -gt 0]; then
		sbegin "Shredding secondary drives"
		for d in ${sdrive_ids[@]}; do
			slog "Shredding /dev/$d."
			shred -vn 1 /dev/$d
		done
		sdone
	fi
fi
sbegin "Wiping primary drive"
sfdisk -w /dev/$primary_drive
sdone
sbegin "Partitioning primary drive"
echo -e "label: gpt\n size=1G, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B\n size=$swap_size, type=S\n size=+, type=4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709\n" | sfdisk /dev/$primary_drive
sdone
if [sdrive_count -gt 0]; then
	sbegin "Partitioning secondary drives"
	for d in ${sdrive_ids[@]}; do
		slog "Partitioning drive /dev/$d"
		echo -e "label: gpt\n size+, type=F\n" | sfdisk /dev/$d
	done
	sdone
fi
sbegin "Formatting primary drive partitions"
mkfs.fat -F 32 /dev/${primary_drive}1
mkswap /dev/${primary_drive}2
mkfs.ext4 /dev/${primary_drive}3
sdone
if [sdrive_count -gt 0]; then
	sbegin "Formatting secondary drive partitions"
	for d in ${sdrive_ids[@]}; do
		slog "Formating partition /dev/${d}1"
		mkfs.ext4 /dev/${d}1
	done
	sdone
fi
slog "Mounting partitions."
sbegin "Mounting primary drive partitions"
mount /dev/$root_partition /mnt
mount --mkdir /dev/$efi_partition /mnt/boot
sdone
if [sdrive_count -gt 0]; then
	sbegin "Mounting secondary drive partitions"
	mkdir /mnt/drives
	for i in ${!sdrive_ids[@]}; do
		slog "Mounting partition /dev/${sdrive_ids[$i]}1 at /mnt/drives/${sdrive_names[$i]}"
		mount --mkdir /dev/${sdrive_ids[$i]}1 /mnt/drives/${sdrive_names[$i]}
	done
	sdone
fi
sbegin "Enabling swap"
swapon /dev/$swap_partition
sdone
#Package Installation
sbegin "Refreshing mirrors"
reflector_country = `curl https://ipapi.co/country`
reflector -p https -c $reflector_country -l 5 --sort rate --save /etc/pacman.d/mirrorlist
sdone
sbegin "Installing essential packages"
pacstrap -K /mnt base linux linux-firmware efibootmgr grub networkmanager sudo
sdone
#Final Config
sbegin "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab
sdone
#Move Installer to Arch-Chroot
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