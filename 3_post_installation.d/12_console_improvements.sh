# https://wiki.archlinux.org/index.php/general_recommendations#Console_improvements

source common.sh

print_section "Console improvements"

# https://wiki.archlinux.org/index.php/general_recommendations#Mouse_support
print_subsection "Mouse support"
# https://wiki.archlinux.org/index.php/General_purpose_mouse
pacman_sync gpm || die "Couldn't install 'gpm'."
systemctl enable --now gpm.service || die "Couldn't start 'gpm.service'."
