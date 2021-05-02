# https://wiki.archlinux.org/index.php/general_recommendations#Networking

source common.sh

print_section "Networking"

if test_to_agree "Do install bluetooth utilites (bluez, bluez-utils)?"; then
	# https://wiki.archlinux.org/index.php/bluetooth#Installation
	pacman_sync bluez{,-utils} || die "Couldn't install Bluetooth tools."
	systemctl enable --now bluetooth.service \
		|| die "Couldn't start 'bluetooth.service'."
fi

# https://wiki.archlinux.org/index.php/General_recommendations#Clock_synchronization
print_subsection "Clock synchronization"
# https://wiki.archlinux.org/index.php/Systemd-timesyncd#Usage
timedatectl set-ntp true || die "Couldn't enable NTP."

# https://wiki.archlinux.org/index.php/general_recommendations#DNS_security
print_subsection "DNS security"
# dhcpcd can owerwrite 'resolv.conf'
# https://wiki.archlinux.org/index.php/Dhcpcd#resolv.conf
systemctl disable --now dhcpcd.service

# https://wiki.archlinux.org/index.php/systemd-resolved#Configuration
ln --symbolic --force /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
systemctl enable --now systemd-resolved.service \
	|| die "Couldn't start 'systemd-resolved.service'."

# https://wiki.archlinux.org/index.php/systemd-resolved#Automatically
# https://wiki.archlinux.org/index.php/systemd-resolved#Configuration
# https://wiki.archlinux.org/index.php/Systemd-networkd#network_files
cat <<'EOF' > /etc/systemd/network/99-default.network
[Match]
Type=ether wlan

[Network]
DHCP=yes
EOF
# https://wiki.archlinux.org/index.php/Systemd-networkd#Required_services_and_setup
systemctl enable --now systemd-networkd.service \
	|| die "Couldn't enable 'systemd-networkd.service'."

# https://wiki.archlinux.org/index.php/Network_configuration#Check_the_connection
retry ping -c1 archlinux.org || die "Couldn't ping 'archlinux.org'."

# https://wiki.archlinux.org/index.php/general_recommendations#Setting_up_a_firewall
# https://wiki.archlinux.org/index.php/Security#Firewalls
print_subsection "Setting up a firewall"
# https://wiki.archlinux.org/index.php/nftables#Installation
pacman_sync nftables || die "Couldn't install 'nftables'."
# https://wiki.archlinux.org/index.php/nftables#Configuration
# shellcheck disable=SC1004
sed --in-place '
  # https://wiki.archlinux.org/index.php/nftables#Limit_rate_IPv4.2FIPv6_firewall
  s/tcp dport ssh .*/tcp dport ssh ct state new limit rate 15\/minute accept/

  # https://wiki.archlinux.org/index.php/PPTP_Client#Troubleshooting
  # remove old GRE settings
  /# allow GRE/,/^$/ d
  # add new GRE settings
  /# early drop of invalid connections/ i\
    # allow GRE (before drop of invalid connections)\
    #ip protocol gre accept\

  # https://www.cups.org/doc/network.html#SNMP
  # remove old SNMP settings
  /# allow SNMP Manager/,/^$/ d
  # add new SNMP settings
  /# everything else/ i\
    # allow SNMP Manager\
    #udp sport snmp accept\
    #udp dport snmp-trap accept\n

  # https://wiki.archlinux.org/index.php/systemd-resolved#mDNS
  # remove old mDNS settings
  /# allow mDNS/,/^$/ d
  # add new mDNS settings
  /# everything else/ i\
    # allow mDNS\
    #ip daddr 224.0.0.251 udp dport mdns accept\
    #ip6 daddr ff02::fb udp dport mdns accept\n

  # https://wiki.archlinux.org/index.php/systemd-resolved#LLMNR
  # remove old LLMNR settings
  /# allow LLMNR/,/^$/d
  # add new LLMNR settings
  /# everything else/i\
    # allow LLMNR\
    #tcp dport hostmon accept\
    #udp dport hostmon accept\n

  # https://wiki.archlinux.org/index.php/TigerVNC#On_demand_multi-user_mode
  # remove old VNC settings
  /# allow VNC/,/^$/ d
  # add new VNC settings
  /# everything else/ i\
    # allow VNC\
    #tcp dport 5900 accept\n

  # https://wiki.archlinux.org/index.php/PulseAudio#On_the_server
  # remove old PulseAudio network server settings
  /# allow PulseAudio network server/,/^$/ d
  # add new PulseAudio network server settings
  /# everything else/ i\
    # allow PulseAudio network server\
    #tcp dport 4713 accept\n

  # https://wiki.archlinux.org/index.php/Nftables#Working_with_Docker
  # accept the forward chain to allow traffic from Docker containers
  /type filter hook forward/,/}/ s/^\(\s*\)\(drop\)$/\1#\2/
' /etc/nftables.conf || "Couldn't patch '/etc/nftables.conf'."
# https://wiki.archlinux.org/index.php/nftables#Usage
systemctl enable --now nftables.service \
	|| die "Couldn't start 'nftables.service'."

# https://wiki.archlinux.org/index.php/general_recommendations#Resource_sharing
print_subsection "Resource sharing"
if test_to_agree "Do install smbclient?"; then
	# https://wiki.archlinux.org/index.php/Samba#Client
	pacman_sync smbclient || die "Couldn't install 'smbclient'."
	mkdir --parent /etc/samba
	touch /etc/samba/smb.conf
fi
