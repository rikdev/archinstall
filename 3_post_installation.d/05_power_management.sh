# https://wiki.archlinux.org/index.php/general_recommendations#Power_management

source common.sh

print_section "Power management"

# https://wiki.archlinux.org/index.php/Display_Power_Management_Signaling#DPMS_interaction_in_a_Linux_console_with_setterm
print_subsection "DPMS"
readonly GETTY_SERVICE_D_PATH=/etc/systemd/system/getty@.service.d
mkdir --parent "${GETTY_SERVICE_D_PATH}"
cat <<'EOF' > "${GETTY_SERVICE_D_PATH}/enable-dpms.conf"
[Service]
ExecStartPre=/bin/sh -c \
  "setterm -blank 10 >> /dev/%I \
  && setterm -powerdown 1 >> /dev/%I \
  && setterm -powersave on >> /dev/%I"
EOF

# https://wiki.archlinux.org/index.php/general_recommendations#Suspend_and_Hibernate
print_subsection "Suspend and Hibernate"
readonly SWAP_FILE_PATH="/${SWAP_FILE_NAME}"
if swapon --show=NAME | grep --silent "${SWAP_FILE_PATH}"; then
  # https://wiki.archlinux.org/index.php/Power_management/Suspend_and_hibernate#Required_kernel_parameters
  readonly SWAP_PARTITION_DEVNAME="$(\
    df "${SWAP_FILE_PATH}" | awk 'NR == 2 { print $1 }')"
  readonly SWAP_PARTITION_UUID="$(\
    blkid --output value --match-tag UUID "${SWAP_PARTITION_DEVNAME}")" \
    || die "Couldn't get swap partition UUID."
  readonly SWAP_FILE_OFFSET="$(\
    filefrag -v "${SWAP_FILE_PATH}" \
    | awk 'NR == 4 { print substr($4, 0, length($4)-2) }')"
  [[ -n "${SWAP_FILE_OFFSET}" ]] || die "Couldn't get swap file offset"
  sed --in-place '
    /GRUB_CMDLINE_LINUX_DEFAULT=/ {
        # remove old "resume" and "resume_offset" parameters
        s/ *\bresume=[^ "]*\| *\bresume_offset=[^ "]*//g
        # add new "resume" and "resume_offset" parameters
        s/"\(.*\)"/"\1 resume=UUID='"${SWAP_PARTITION_UUID}"' resume_offset='"${SWAP_FILE_OFFSET}"'"/
    }
  ' /etc/default/grub || "Couldn't patch '/etc/default/grub'."
  grub-mkconfig --output=/boot/grub/grub.cfg \
    || die "Couldn't make '/boot/grub/grub.cfg'."
  # https://wiki.archlinux.org/index.php/Power_management/Suspend_and_hibernate#Configure_the_initramfs
  if ! grep --silent 'HOOKS=(.*\bresume.*)\|HOOKS=(.*\bsystemd.*)' /etc/mkinitcpio.conf; then
    sed --in-place '/HOOKS=/ s/(\(.*\))/(\1 resume)/' /etc/mkinitcpio.conf \
      || "Couldn't patch '/etc/mkinitcpio.conf'."
    mkinitcpio --preset linux || "Couldn't make initramfs CPIO."
  fi
fi

# https://wiki.archlinux.org/index.php/Power_management#Sleep_hooks
pacman_sync physlock || die "Couldn't install 'physlock'."
readonly TLOCK_PATH=/usr/local/bin/tlock
cat <<'EOF' > "${TLOCK_PATH}"
#!/bin/bash

readonly ACTIVE_TTY="$(cat /sys/class/tty/tty0/active)"
readonly ACTIVE_USER="$(loginctl list-sessions\
  | awk -v tty="$ACTIVE_TTY" 'NR > 1 { if ($5 == tty) print $3 }')"
[[ -n "${ACTIVE_USER}" ]] || exit 1
physlock -p "User: $ACTIVE_USER" "$@"
EOF
chmod +x "${TLOCK_PATH}"

readonly ROOT_SUSPEND_SERVICE_NAME="root-suspend.service"
cat <<EOF > "/etc/systemd/system/${ROOT_SUSPEND_SERVICE_NAME}"
[Unit]
Description=User suspend actions
Before=sleep.target

[Service]
Type=forking
ExecStart="${TLOCK_PATH}" -d

[Install]
WantedBy=sleep.target
EOF
systemctl enable "${ROOT_SUSPEND_SERVICE_NAME}" \
  || "Couldn't enable '${ROOT_SUSPEND_SERVICE_NAME}'."

# https://upower.freedesktop.org/
pacman_sync upower || die "Couldn't install 'upower'."
udevadm_reload
sed --in-place \
  --expression 's/^\(PercentageLow\)=.*/\1=50/' \
  --expression 's/^\(PercentageCritical\)=.*/\1=40/' \
  --expression 's/^\(PercentageAction\)=.*/\1=30/' \
  /etc/UPower/UPower.conf || die "Couldn't patch '/etc/UPower/UPower.conf'."
systemctl_permanently_start upower.service \
  || die "Couldn't start 'upower.service'."

# https://wiki.archlinux.org/index.php/Power_management#Audio
print_subsection "Audio"
cat <<'EOF' > /etc/modprobe.d/audio_powersave.conf
options snd_hda_intel power_save=1
options snd_ac97_codec power_save=1
EOF
