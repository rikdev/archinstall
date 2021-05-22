# https://wiki.archlinux.org/index.php/General_recommendations#Optimization

source common.sh

print_section "Optimization"

# https://wiki.archlinux.org/index.php/General_recommendations#Improving_performance
print_subsection "Improving performance"
# https://wiki.archlinux.org/index.php/Improving_performance#Changing_I.2FO_scheduler
readonly IOSCHEDULERS_RULES_FILE_PATH=/etc/udev/rules.d/60-ioschedulers.rules
cat <<'EOF' > "${IOSCHEDULERS_RULES_FILE_PATH}"
# set scheduler for non-rotating disks
ACTION=="add|change", KERNEL=="sd[a-z]|mmcblk[0-9]*|nvme[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="noop"
EOF
# https://wiki.archlinux.org/index.php/Udev#Loading_new_rules
udevadm_reload || die "Couldn't load '${IOSCHEDULERS_RULES_FILE_PATH}'."

# https://wiki.archlinux.org/index.php/Systemd#Temporary_files
readonly ZSWAP_CONF_FILE_PATH=/etc/tmpfiles.d/enable-zswap.conf
cat <<'EOF' > "${ZSWAP_CONF_FILE_PATH}"
#Type Path                                    Mode UID GID Age Argument
# https://wiki.archlinux.org/index.php/Zswap#Enabling_zswap
w     /sys/module/zswap/parameters/enabled    -    -   -   -   1
# https://wiki.archlinux.org/index.php/Zswap#Compression_algorithm
w     /sys/module/zswap/parameters/compressor -    -   -   -   lz4
# https://wiki.archlinux.org/index.php/Zswap#Compressed_memory_pool_allocator
w     /sys/module/zswap/parameters/zpool      -    -   -   -   z3fold
EOF
systemd-tmpfiles --create "${ZSWAP_CONF_FILE_PATH}" \
	|| die "Couldn't apply '${ZSWAP_CONF_FILE_PATH}'."

#https://wiki.archlinux.org/title/Improving_performance#Improving_system_responsiveness_under_low-memory_conditions
systemctl enable --now systemd-oomd.service || die "Couldn't start 'systemd-oomd.service'."

# https://wiki.archlinux.org/index.php/Improving_performance#Watchdogs
cat <<'EOF' > /etc/modprobe.d/blacklist-watchdogs.conf
blacklist iTCO_wdt
blacklist mei_wdt
EOF
# https://wiki.archlinux.org/index.php/Power_management#Disabling_NMI_watchdog
readonly WATCHDOGS_CONF_FILE_PATH=/etc/sysctl.d/watchdogs.conf
cat <<'EOF' > "${WATCHDOGS_CONF_FILE_PATH}"
kernel.nmi_watchdog = 0
kernel.soft_watchdog = 0
kernel.watchdog = 0
EOF
sysctl --load="${WATCHDOGS_CONF_FILE_PATH}" \
	|| die "Couldn't load '${WATCHDOGS_CONF_FILE_PATH}'"
# https://wiki.archlinux.org/index.php/general_recommendations#Solid_state_drives
# https://wiki.archlinux.org/index.php/Solid_state_drive#Periodic_TRIM
systemctl enable --now fstrim.timer || die "Couldn't start 'fstrim.timer'."
