# https://wiki.archlinux.org/index.php/general_recommendations#Appearance

source common.sh

print_section "Appearance"

# https://wiki.archlinux.org/index.php/general_recommendations#GTK.2B_and_Qt_themes
print_subsection "GTK+ and Qt themes"
# https://wiki.archlinux.org/index.php/Uniform_look_for_Qt_and_GTK_applications#QGtkStyle
pacman_sync qt5-styleplugins gnome-themes-extra \
  || die "Couldn't install themes."
readonly THEME_SETTINGS_PATH=/etc/X11/xinit/xinitrc.d/98-theme-settings.sh
cat <<'EOF' > "${THEME_SETTINGS_PATH}"
# https://wiki.archlinux.org/index.php/Uniform_look_for_Qt_and_GTK_applications#QGtkStyle
export QT_QPA_PLATFORMTHEME=gtk2
# https://wiki.archlinux.org/index.php/GTK%2B#Themes
export GTK2_RC_FILES=/usr/share/themes/Adwaita/gtk-2.0/gtkrc
export GTK_THEME=Adwaita
EOF
chmod +x "${THEME_SETTINGS_PATH}"
cat <<'EOF' > /etc/xdg/Trolltech.conf
[Qt]
style=GTK+
EOF
