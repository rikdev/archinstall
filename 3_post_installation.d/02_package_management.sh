# https://wiki.archlinux.org/index.php/General_recommendations#Package_management

source common.sh

print_section "Package management"

# https://wiki.archlinux.org/index.php/General_recommendations#pacman
print_subsection "Pacman"
# https://wiki.archlinux.org/index.php/Pacman#Cleaning_the_package_cache
pacman_sync pacman-contrib || die "Couldn't install 'pacman-contrib'."
systemctl enable --now paccache.timer || die "Couldn't start 'paccache.timer'."

# https://wiki.archlinux.org/index.php/General_recommendations#Repositories
print_subsection "Repositories"
sed --in-place '/\[multilib\]/,/^$/ s/#//' /etc/pacman.conf \
	|| die "Couldn't patch '/etc/pacman.conf'."
pacman --sync --noconfirm --refresh --sysupgrade \
	|| die "Couldn't refresh package databases."

# https://wiki.archlinux.org/index.php/general_recommendations#Arch_User_Repository
print_subsection "Arch User Repository"
pacman_sync base-devel || die "Couldn't install 'base-devel'."
