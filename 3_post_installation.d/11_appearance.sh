# https://wiki.archlinux.org/index.php/general_recommendations#Appearance

source common.sh

print_section "Appearance"

# https://wiki.archlinux.org/index.php/general_recommendations#GTK_and_Qt_themes
print_subsection "GTK and Qt themes"
# https://wiki.archlinux.org/index.php/Uniform_look_for_Qt_and_GTK_applications#Adwaita
pacman_sync gnome-themes-extra || die "Couldn't 'gnome-themes-extra'."
