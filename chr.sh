# Saki's Arch Installer v2.2.0 - Chroot Portion
#colours
noformat="\033[0m"
font="\033[38;5;"
bgr="\033[48;5;"
green="2m"
teal="6m"
olive="3m"
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
	sbegin "$1"
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
echo "root:$q_root_password" | chpasswd
if [ $q_zsh = "y" ]; then
	snext "Setting root shell to zsh"
	chsh -s /bin/zsh
fi
if [ $q_ssh = "y" ]; then
	snext "Setting up openssh"
	slog "Configuring ssh server."
	groupadd ssh
	printf "HostKey /etc/ssh/ssh_host_ed25519_key\nAllowGroups ssh" > /etc/ssh/sshd_config
	slog "Generating ssh keys."
	ssh-keygen -A
	slog "Starting open ssh service."
	systemctl enable sshd.service
fi
if [ $q_reflector = "y" ]; then
	snext "Setting up reflector"
	slog "Configuring reflector."
	tmp=`curl https://ipapi.co/country`
	echo "-p https -c $tmp -l 5 --sort rate --save /etc/pacman.d/mirrorlist" > /etc/xdg/reflector/reflector.conf
	slog "Enabling reflector boot service."
	systemctl enable reflector.service
fi
#User Setup
if [ $user_count -gt 0 ]; then
	for i in ${!user_names[@]}; do
		snext "Setting up user: ${user_names[$i]}"
		slog "Creating user."
		useradd -m ${user_names[$i]}
		slog "Setting user password."
		echo "${user_names[$i]}:${user_passwords[$i]}" | chpasswd
		if [[ ${user_sudo[$i]} = "y" || ${user_sudo[$i]} = "Y" ]]; then
			slog "Adding user to wheel group."
			gpasswd -a ${user_names[$i]} wheel
		fi
		if [[ ${user_ssh[$i]} = "y" || ${user_ssh[$i]} = "Y" ]]; then
			slog "Adding user to ssh group."
			gpasswd -a ${user_names[$i]} ssh
		fi
		if [ $q_zsh = "y" ]; then
			slog "Setting user shell to zsh."
			usermod -s /bin/zsh ${user_names[$i]}
		fi
		if [ $sdrive_count -gt 0 ]; then
			if [ $q_sdrive_symlink = "y" ]; then
				mkdir -p /home/${user_names[$i]}/drives
			fi
			for j in ${!sdrive_ids[@]}; do
				mkdir /drives/${sdrive_names[$j]}/${user_names[$i]}
				if [ $q_sdrive_symlink = "y" ]; then
					ln -s /drives/${sdrive_names[$j]}/${user_names[$i]} /home/${user_names[$i]}/drives/${sdrive_names[$j]}
					chown ${user_names[$i]} /home/${user_names[$i]}/drives/${sdrive_names[$j]}
				fi
				chown ${user_names[$i]} /drives/${sdrive_names[$j]}/${user_names[$i]}
			done
			if [ $q_sdrive_symlink = "y" ]; then
				chown ${user_names[$i]} /home/${user_names[$i]}/drives
			fi
		fi
	done
fi
snext "Removing self"
rm -rf /chr.sh
sdone
printf "$font$green$1Arch installation complete. You may now reboot!$noformat\n"