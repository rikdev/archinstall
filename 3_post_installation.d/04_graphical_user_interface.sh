# https://wiki.archlinux.org/index.php/General_recommendations#Graphical_user_interface

source common.sh

print_section "Graphical user interface"

# https://wiki.archlinux.org/index.php/General_recommendations#Display_server
print_subsection "Display server"
pacman_sync fontconfig || die "Couldn't install 'fontconfig'."
# https://wiki.archlinux.org/index.php/Font_configuration#Presets
ln --symbolic --force /etc/fonts/conf.avail/10-sub-pixel-rgb.conf /etc/fonts/conf.d/
ln --symbolic --force /etc/fonts/conf.avail/11-lcdfilter-default.conf /etc/fonts/conf.d/

# https://wiki.archlinux.org/index.php/general_recommendations#Display_drivers
print_subsection "Display drivers"
# https://wiki.archlinux.org/index.php/Hyper-V#Xorg
if hostnamectl | grep --silent '\bVirtualization: microsoft\b'; then
	pacman_sync xf86-video-fbdev || die "Couldn't install 'xf86-video-fbdev'."
fi

# https://wiki.archlinux.org/index.php/General_recommendations#User_directories
print_subsection "User directories"
pacman_sync xdg-user-dirs || die "Couldn't install 'xdg-user-dirs'."
