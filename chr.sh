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
slog "Secondary script running, and utility functions setup."
#initial setup stuffs
sbegin "Setting up timezone"
tmp=`curl https://ipapi.co/timezone`
timedatectl set-timezone $tmp
hwclock --systohc
sdone
