# https://wiki.archlinux.org/index.php/General_recommendations#Multimedia

source common.sh

print_section "Multimedia"

# https://wiki.archlinux.org/title/General_recommendations#Sound_system
print_subsection "Sound"
pacman_sync alsa-utils || die "Couldn't install 'alsa-utils'."
amixer sset Master unmute 100 || true

# https://wiki.archlinux.org/title/PipeWire#Installation
pacman_sync pipewire || die "Couldn't install 'PipeWire'."
