# https://wiki.archlinux.org/index.php/General_recommendations#Multimedia

source common.sh

print_section "Multimedia"

# https://wiki.archlinux.org/index.php/General_recommendations#Sound
print_subsection "Sound"
pacman_sync alsa-utils || die "Couldn't install 'alsa-utils'."
amixer sset Master unmute 100 || true

# https://wiki.archlinux.org/index.php/PulseAudio#Installation
pacman_sync pulseaudio pulseaudio-bluetooth \
  || die "Couldn't install PulseAudio."
pulseaudio --start || die "Couldn't start PulseAudio."
