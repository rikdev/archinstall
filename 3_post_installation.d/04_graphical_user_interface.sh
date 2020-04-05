# https://wiki.archlinux.org/index.php/General_recommendations#Graphical_user_interface

source common.sh

print_section "Graphical user interface"

# https://wiki.archlinux.org/index.php/General_recommendations#Display_server
print_subsection "Display server"
pacman_sync xorg-server || die "Couldn't install 'xorg-server'."

# https://wiki.archlinux.org/index.php/Keyboard_configuration_in_Xorg#Using_X_configuration_files
cat <<'EOF' > /etc/X11/xorg.conf.d/00-keyboard.conf
Section "InputClass"
        Identifier "system-keyboard"
        MatchIsKeyboard "on"
        Option "XkbLayout" "us,ru"
        Option "XkbOptions" "grp:caps_toggle,grp_led:scroll,terminate:ctrl_alt_bksp"
EndSection
EOF

pacman_sync xorg-xinit || die "Couldn't install 'xorg-xinit'."
# https://wiki.archlinux.org/index.php/Xinit#xserverrc
# https://wiki.archlinux.org/index.php/Keyboard_configuration_in_Xorg#Using_XServer_startup_options
cat <<'EOF' > /etc/X11/xinit/xserverrc
#!/bin/sh
exec /usr/bin/X \
  -nolisten tcp \
  -nolisten local \
  -ardelay 200 \
  -arinterval 30 \
  "$@" vt$XDG_VTNR
EOF

echo -n > /etc/X11/xinit/.Xresources

pacman_sync xorg-xset || die "Couldn't install 'xorg-xset'."
# https://wiki.archlinux.org/index.php/Display_Power_Management_Signaling#Modifying_DPMS_and_screensaver_settings_using_xset
readonly DPMS_SETTINGS_PATH=/etc/X11/xinit/xinitrc.d/98-dpms-settings.sh
cat << 'EOF' > "${DPMS_SETTINGS_PATH}"
xset s off
xset dpms 600 600 600
EOF
chmod +x "${DPMS_SETTINGS_PATH}"
# Method https://wiki.archlinux.org/index.php/Display_Power_Management_Signaling#Setting_up_DPMS_in_X
# doesn't work

pacman_sync fontconfig || die "Couldn't install 'fontconfig'."
# https://wiki.archlinux.org/index.php/Font_configuration#Presets
ln --symbolic --force /etc/fonts/conf.avail/10-sub-pixel-rgb.conf /etc/fonts/conf.d/
ln --symbolic --force /etc/fonts/conf.avail/11-lcdfilter-default.conf /etc/fonts/conf.d/
cat <<'EOF' >> /etc/X11/xinit/.Xresources
! Xft setting
! https://wiki.archlinux.org/index.php/Font_configuration#Applications_without_fontconfig_support
Xft.autohint: 0
Xft.lcdfilter: lcddefault
Xft.hintstyle: hintslight
Xft.hinting: 1
Xft.antialias: 1
Xft.rgba: rgb
EOF

# https://wiki.archlinux.org/index.php/Fonts
pacman_sync xorg-fonts-{misc,cyrillic} ttf-dejavu \
  || die "Couldn't install fonts."
if [[ -n "${DISPLAY:-}" ]]; then
  xset fp rehash || die "Couldn't reread font databases."
fi

# https://wiki.archlinux.org/index.php/Cursor_themes
pacman_sync adwaita-icon-theme \
  || die "Couldn't install 'adwaita-icon-theme'."
cat <<'EOF' >> /etc/X11/xinit/.Xresources
! Cursor setting
! https://wiki.archlinux.org/index.php/Cursor_themes#X_resources
Xcursor.theme: Adwaita
EOF

if test_to_agree "Do install optional software (xterm)?"; then
  pacman_sync xterm || die "Couldn't install 'xterm'."
  cat <<'EOF' >> /etc/X11/xinit/.Xresources
! xterm settings
! https://wiki.archlinux.org/index.php/Xterm#Configuration
! https://wiki.archlinux.org/index.php/Xterm#TERM_Environmental_Variable
xterm.*.termName: xterm-256color
! https://wiki.archlinux.org/index.php/Xterm#UTF-8
xterm.*.vt100.locale: true
! https://wiki.archlinux.org/index.php/Xterm#Make_.27Alt.27_key_behave_as_on_other_terminal_emulators
xterm.*.vt100.metaSendsEscape: true
! https://wiki.archlinux.org/index.php/Xterm#Fix_the_backspace_key
xterm.*.vt100.backarrowKey: false
xterm.ttyModes: erase ^?
! https://wiki.archlinux.org/index.php/Xterm#Scrolling
xterm.*.vt100.saveLines: 4096
! https://wiki.archlinux.org/index.php/Xterm#Scrollbar
xterm.*.vt100.scrollBar: false
xterm.*.vt100.scrollBar.width: 8
xterm.*.vt100.rightScrollBar: true
! https://wiki.archlinux.org/index.php/Xterm#Colors
xterm.*.vt100.foreground: white
xterm.*.vt100.background: black
! https://wiki.archlinux.org/index.php/Xterm#Default_fonts
xterm.*.vt100.faceName: DejaVu Sans Mono
xterm.*.vt100.faceSize: 10
! https://wiki.archlinux.org/index.php/Xterm#Enable_bell_urgency
xterm.*.vt100.bellIsUrgent: true
! https://wiki.archlinux.org/index.php/Xterm#Adjust_line_spacing
xterm.*.vt100.scaleHeight: 1.01
EOF
fi

# https://wiki.archlinux.org/index.php/general_recommendations#Display_drivers
print_subsection "Display drivers"
# https://wiki.archlinux.org/index.php/Hyper-V#Xorg
if hostnamectl | grep --silent '\bVirtualization: microsoft\b'; then
  pacman_sync xf86-video-fbdev || die "Couldn't install 'xf86-video-fbdev'."
fi

# https://wiki.archlinux.org/index.php/General_recommendations#Window_managers
print_subsection "Window managers"
# https://wiki.archlinux.org/index.php/I3
pacman_sync i3-wm i3status i3lock || die "Couldn't install i3."
readonly WINDOW_MANAGER_PATH=/etc/X11/xinit/xinitrc.d/99-window-manager.sh
echo 'exec i3' > "${WINDOW_MANAGER_PATH}"
chmod +x "${WINDOW_MANAGER_PATH}"

# https://wiki.archlinux.org/index.php/I3#Application_launcher
pacman_sync dmenu || die "Couldn't install 'dmenu'."

# https://wiki.archlinux.org/index.php/general_recommendations#Display_manager
print_subsection "Display manager"
# https://wiki.archlinux.org/index.php/Xinit#Autostart_X_at_login
# shellcheck disable=SC2016
echo '[ -z "${DISPLAY:-}" -a "$(tty)" = "/dev/tty1" ] && exec startx' \
  > /etc/profile.d/startx.sh

# https://wiki.archlinux.org/index.php/General_recommendations#User_directories
print_subsection "User directories"
pacman_sync xdg-user-dirs || die "Couldn't install 'xdg-user-dirs'."
