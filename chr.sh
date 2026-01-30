# Saki's Arch Installer v2.0 - Chroot Portion
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
snext () {
	sdone
	sbegin $1
}
slog "Secondary script running, and utility functions setup."
#initial setup stuffs
sbegin "Setting up timezone"
tmp=`curl https://ipapi.co/timezone`
timedatectl set-timezone $tmp
hwclock --systohc
snext "Generating locales"
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "$q_hostname" > /etc/hostname
snext "Installing grub"
grub-install --target=x86_64-efi --efi-directory=/boot --removable
grub-mkconfig -o /boot/grub/grub.cfg
snext "Setting wheel group as sudoers"
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
snext "Enabling network manager service"
systemctl enable NetworkManager.service
snext "Setting root password"
echo $q_root_password | passwd -s root
sdone
if [ $q_ssh = "y" ]; then
	sbegin "Configuring ssh server"
	groupadd ssh
	printf "HostKey /etc/ssh/ssh_host_ed25519_key\nAllowGroups ssh" > /etc/ssh/sshd_config
	snext "generating ssh keys..."
	ssh-keygen -A
	snext "starting open ssh service..."
	systemctl enable sshd.service
	sdone
fi
if [ $q_reflector = "y" ]; then
	sbegin "Configuring reflector"
	tmp = `curl https://ipapi.co/country`
	echo "-p https -c $tmp -l 5 --sort rate --save /etc/pacman.d/mirrorlist" > /etc/xdg/reflector/reflector.conf && break
	snext "enabling reflector boot service"
	systemctl enable reflector.service
	sdone
fi
slog "Root install complete, moving on to user config"
#TODO user setup