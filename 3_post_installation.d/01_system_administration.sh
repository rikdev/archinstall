# https://wiki.archlinux.org/index.php/General_recommendations#System_administration

source common.sh

print_section "System administration"

# https://wiki.archlinux.org/index.php/General_recommendations#Users_and_groups
print_subsection "Users and groups"
if test_to_agree "Do add a new admin user?"; then
	read -r -p "Input your username: "
	[[ -n "${REPLY}" ]] || die "Invalid username."
	# https://wiki.archlinux.org/index.php/Users_and_groups#User_management
	useradd --create-home --groups users,wheel "${REPLY}" \
		|| die "Couldn't create user with name '${REPLY}'."
	passwd "${REPLY}" || die "Couldn't change password for user '${REPLY}'."
fi

# https://wiki.archlinux.org/index.php/Users_and_groups#Pre-systemd_groups
# https://wiki.archlinux.org/index.php/Udev#Accessing_firmware_programmers_and_USB_virtual_comm_devices
readonly USBSERIAL_RULES_FILE_PATH=/etc/udev/rules.d/50-usbserial.rules
cat <<'EOF' > "${USBSERIAL_RULES_FILE_PATH}"
# Firmware programmers and USB virtual comm devices
SUBSYSTEMS=="usb-serial", TAG+="uaccess"
EOF
# https://wiki.archlinux.org/index.php/Udev#Loading_new_rules
udevadm_reload || die "Couldn't load '${USBSERIAL_RULES_FILE_PATH}'"

# https://wiki.archlinux.org/index.php/General_recommendations#Privilege_escalation
print_subsection "Privilege escalation"
pacman_sync sudo || die "Couldn't install 'sudo'."
echo '%wheel ALL=(ALL) ALL' > /etc/sudoers.d/wheel
echo 'Defaults passwd_timeout=0' > /etc/sudoers.d/no-passwd-timeout

# https://wiki.archlinux.org/index.php/Polkit
# https://wiki.archlinux.org/index.php/Systemd#Power_management
pacman_sync polkit || die "Couldn't install 'polkit'."

# https://wiki.archlinux.org/index.php/General_recommendations#System_maintenance
print_subsection "System maintenance"
# https://wiki.archlinux.org/index.php/System_maintenance#Install_the_linux-lts_package
pacman_sync linux-lts || die "Couldn't install 'linux-lts'."
grub-mkconfig -o /boot/grub/grub.cfg

# https://wiki.archlinux.org/index.php/Security#Restricting_root_login
if [[ "$(passwd --status root | cut --field=2 --delimiter=' ')" != 'L' ]]; then
	if test_to_agree "Do lock the password of the root account?"; then
		passwd --lock root || die "Couldn't lock root account."
	fi
fi

# https://wiki.archlinux.org/index.php/Security#Allow_only_certain_users
print_subsection "Allow only certain users"
sed --in-place '/^#\s*auth\s\+required\s\+pam_wheel/ s/#//' /etc/pam.d/su{,-l} \
	|| die "Couldn't patch '/etc/pam.d/su{,-l}'."

# https://wiki.archlinux.org/index.php/Security#Kernel_hardening

print_subsection "Keyboard shortcuts"
# https://wiki.archlinux.org/index.php/Keyboard_shortcuts#Kernel
readonly SYSRQ_CONF_FILE_PATH=/etc/sysctl.d/sysrq.conf
echo 'kernel.sysrq = 1' > "${SYSRQ_CONF_FILE_PATH}"
sysctl --load="${SYSRQ_CONF_FILE_PATH}" \
	|| die "Couldn't load '${SYSRQ_CONF_FILE_PATH}'."
