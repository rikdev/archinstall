# https://wiki.archlinux.org/index.php/General_recommendations#Booting

source common.sh

print_section "Booting"

# https://wiki.archlinux.org/index.php/GRUB#Generate_the_main_configuration_file
print_subsection "GRUB config"
sed --in-place '
	# https://wiki.archlinux.org/index.php/GRUB/Tips_and_tricks#Multiple_entries
	# https://wiki.archlinux.org/index.php/GRUB/Tips_and_tricks#Disable_submenu
	/^#\s*GRUB_DISABLE_SUBMENU=/ s/#//
	# https://wiki.archlinux.org/index.php/GRUB/Tips_and_tricks#Recall_previous_entry
	s/^GRUB_DEFAULT=.*/GRUB_DEFAULT=saved/
	/^#\s*GRUB_SAVEDEFAULT=/ s/#//
' /etc/default/grub || die "Couldn't patch '/etc/default/grub'."
grub-mkconfig --output=/boot/grub/grub.cfg \
	|| die "Couldn't make '/boot/grub/grub.cfg'."

# https://wiki.archlinux.org/index.php/General_recommendations#Hardware_auto-recognition
print_subsection "Hardware auto-recognition"
# https://wiki.archlinux.org/index.php/PC_speaker#Globally
echo 'blacklist pcspkr' > /etc/modprobe.d/nobeep.conf
rmmod pcspkr 2>/dev/null || true

# https://wiki.archlinux.org/index.php/Udisks
pacman_sync udisks2 || die "Couldn't install 'udisks2'."
# https://wiki.archlinux.org/index.php/Systemd#Temporary_files
readonly MEDIA_CONF_FILE_PATH=/etc/tmpfiles.d/create-media-symlink.conf
cat <<'EOF' > "${MEDIA_CONF_FILE_PATH}"
#Type Path       Mode UID GID Age Argument
d     /run/media -    -   -   0   -
L     /media     -    -   -   -   /run/media
EOF
systemd-tmpfiles --create "${MEDIA_CONF_FILE_PATH}" \
	|| die "Couldn't apply '${MEDIA_CONF_FILE_PATH}'."
# Alternative: https://wiki.archlinux.org/index.php/Udisks#Mount_to_.2Fmedia_.28udisks2.29
