# Saki's Arch Installer v2.0 - Archiso Portion
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
user_count=0
user_names=()
user_sudo=()
user_ssh=()
user_passwords=()
q_hostname=""
q_root_password=""
q_sdrive_symlink="n"
q_ssh="n"
q_reflector="n"
q_zsh="n"
q_packages="base linux linux-firmware efibootmgr grub networkmanager sudo"
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
	printf "$font$olive[SAIS](Logger) -> $1$noformat\n"
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
qpasswd () {
	printf "$font${green}Enter password for $1 (Your input will be hidden for security):$noformat "
	read -sr qtmp
	printf "\n$font${green}Confirm password for $1 (Your input will be hidden for security):$noformat "
	read -sr tmp
	while [ $qtmp != $tmp ]; do
		printf "\n$font${green}Error passwords dont match!\nEnter password for $1 (Your input will be hidden for security):$noformat "
		read -sr qtmp
		printf "\n$font${green}Confirm password for $1 (Your input will be hidden for security):$noformat "
		read -sr tmp
	done
	tmp=""
	printf "\n"
}
sdone
clear
#Query User for Install - Query first + Install later allows me to walk away while it installs
slog "Configuring install."
lsblk
qdrive "Enter primary drive"
read primary_drive
qstr "Enter swap size bytes (eg 32G)"
read swap_size
if [ swap_size = "" ]; then
	swap_size="32G"
fi
#sec
qyn "Would you like to add a secondary drive" "n"
read ltmp
while [[ $ltmp = "y" || $ltmp = "Y" ]]; do
	((sdrive_count=sdrive_count+1))
	lsblk
	qdrive "Enter secondary drive"
	read qtmp
	sdrive_ids+=("$qtmp")
	qstr "Name secondary drive (default=drive$sdrive_count)"
	read qtmp
	if [ qtmp = "" ]; then
		qtmp="drive$sdrive_count"
	fi
	sdrive_names+=("$qtmp")
	slog "Drive added."
	qyn "Would you like to add another secondary drive" "n"
	read ltmp
done
qyn "Would you like to shred the drives (replaces all data with random bits)" "n"
read sh_drives
if [[ $sh_drives = "y" || $sh_drives = "Y" ]]; then
	slog "Drives marked for shredding."
fi
#hostname and root
qstr "Enter hostname"
read q_hostname
qpasswd "root"
q_root_password=$qtmp
#ssh
qyn "Would you like to add ssh server capabilities" "n"
read qtmp
if [[ $qtmp = "y" || $qtmp = "Y" ]]; then
	q_packages+=" openssh"
	slog "openssh marked for install."
	q_ssh="y"
	slog "ssh marked for configuration."
fi
#users
qyn "Would you like to create a user" "n"
read ltmp
while [[ $ltmp = "y" || $ltmp = "Y" ]]; do
	((user_count=user_count+1))
	qstr "Enter username"
	read qtmp
	user_names+=("$qtmp")
	qpasswd "user"
	user_passwords+=("$qtmp")
	qyn "Make user a sudoer" "n"
	read qtmp
	user_sudo+=("$qtmp")
	if [ $q_ssh = "y" ]; then
		qyn "Allow ssh access to user" "n"
		read qtmp
		user_ssh+=("$qtmp")
	fi
	qyn "Would you like to create another user" "n"
	read ltmp
done
#ssh
qyn "Would you like to switch default shell to zsh (bash will remain installed, users made with this installer will use zsh)" "n"
read qtmp
if [[ $qtmp = "y" || $qtmp = "Y" ]]; then
	q_packages+=" zsh"
	slog "zsh marked for install."
	q_zsh="y"
	slog "zsh marked for configuration."
fi
qyn "Would you like to enable automatic mirror refreshing on boot using reflector" "n"
read qtmp
if [[ $qtmp = "y" || $qtmp = "Y" ]]; then
	q_packages+=" reflector"
	slog "reflector marked for install."
	q_reflector="y"
	slog "reflector marked for configuration."
fi
#Packages Query
qyn "Would you like to install vim" "n"
read qtmp
if [[ $qtmp = "y" || $qtmp = "Y" ]]; then
	q_packages+=" vim"
	slog "vim marked for install."
fi
qyn "Would you like to install git" "n"
read qtmp
if [[ $qtmp = "y" || $qtmp = "Y" ]]; then
	q_packages+=" git"
	slog "git marked for install."
fi
qyn "Would you like to install base tools for building packages from source" "n"
read qtmp
if [[ $qtmp = "y" || $qtmp = "Y" ]]; then
	q_packages+=" base-devel"
	slog "base-devel marked for install."
fi
#Install
qyn "Final confirmation. begin installation (Warning this will wipe seleced drives and install arch linux on them)" "y"
read qtmp
if [[ $qtmp = "n" || $qtmp = "N" ]]; then
	exit
fi
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
sbegin "Partitioning primary drive"
echo -e "label: gpt\n size=1G, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B\n size=$swap_size, type=S\n size=+, type=4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709\n" | sfdisk -f /dev/$primary_drive
sdone
if [ $sdrive_count -gt 0 ]; then
	sbegin "Partitioning secondary drives"
	for d in ${sdrive_ids[@]}; do
		slog "Partitioning drive /dev/$d"
		echo -e "label: gpt\n size=+, type=F\n" | sfdisk -f /dev/$d
	done
	sdone
fi
sbegin "Formatting primary drive partitions"
mkfs.fat -F 32 /dev/${primary_drive}1
mkswap /dev/${primary_drive}2
mkfs.ext4 -FF /dev/${primary_drive}3
sdone
if [ $sdrive_count -gt 0 ]; then
	sbegin "Formatting secondary drive partitions"
	for d in ${sdrive_ids[@]}; do
		slog "Formating partition /dev/${d}1"
		mkfs.ext4 -FF /dev/${d}1
	done
	sdone
fi
slog "Mounting partitions."
sbegin "Mounting primary drive partitions"
mount /dev/${primary_drive}3 /mnt
mount --mkdir /dev/${primary_drive}1 /mnt/boot
sdone
if [ $sdrive_count -gt 0 ]; then
	sbegin "Mounting secondary drive partitions"
	mkdir /mnt/drives
	for i in ${!sdrive_ids[@]}; do
		slog "Mounting partition /dev/${sdrive_ids[$i]}1 at /mnt/drives/${sdrive_names[$i]}"
		mount --mkdir /dev/${sdrive_ids[$i]}1 /mnt/drives/${sdrive_names[$i]}
	done
	sdone
fi
sbegin "Enabling swap"
swapon /dev/${primary_drive}2
sdone
#Package Installation
sbegin "Refreshing mirrors"
reflector_country = `curl https://ipapi.co/country`
reflector -p https -c $reflector_country -l 5 --sort rate --save /etc/pacman.d/mirrorlist
sdone
sbegin "Installing essential packages"
pacstrap -K /mnt $q_packages
sdone
#Final Config
sbegin "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab
sdone
#Generate second script
sbegin "Transfering variables to secondary install script"
echo -n "# Autogenerated Variable Transfer\n" > /mnt/chr.sh
vtrans () {
	echo -n $1 >> /mnt/chr.sh
}
vtrans "sdrive_count=$sdrive_count"
vtrans "sdrive_ids=("
for d in ${sdrive_ids[@]}; do
	vtrans "\"$d\" "
done
vtrans ")\n"
vtrans "sdrive_names=("
for d in ${sdrive_names[@]}; do
	vtrans "\"$d\" "
done
vtrans ")\n"
vtrans "user_count=\"$user_count\""
vtrans "user_names=("
for d in ${user_names[@]}; do
	vtrans "\"$d\" "
done
vtrans ")\n"
vtrans "user_sudo=("
for d in ${user_sudo[@]}; do
	vtrans "\"$d\" "
done
vtrans ")\n"
vtrans "user_ssh=("
for d in ${user_ssh[@]}; do
	vtrans "\"$d\" "
done
vtrans ")\n"
vtrans "user_passwords=("
for d in ${user_passwords[@]}; do
	vtrans "\"$d\" "
done
vtrans ")\n"
vtrans "q_hostname=\"$q_hostname\"\n"
vtrans "q_root_password=\"$q_root_password\"\n"
vtrans "q_sdrive_symlink=\"$q_sdrive_symlink\"\n"
vtrans "q_ssh=\"$q_ssh\"\n"
vtrans "q_reflector=\"$q_reflector\"\n"
vtrans "q_zsh=\"$q_zsh\"\n"
sdone
sbegin "Fetching secondary install script"
curl "https://svsais.github.io/sais/chr.sh" >> /mnt/chr.sh
sdone
sbegin "Making secondary script runnable"
chmod a+x /mnt/chr.sh
sdone
#Move install to chroot
sbegin "Removing self"
rm -rf /ais.sh
sdone
slog "Launching secondary script in arch-chroot."
arch-chroot /mnt /chr.sh