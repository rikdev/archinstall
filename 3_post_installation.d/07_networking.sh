# https://wiki.archlinux.org/index.php/general_recommendations#Networking

source common.sh

print_section "Networking"

if test_to_agree "Do install Wi-Fi utilites (iw, wpa_supplicant)?"; then
  # https://wiki.archlinux.org/index.php/Wireless_network_configuration
  pacman_sync iw wpa_supplicant || die "Couldn't install Wi-Fi utilites."
  # https://wiki.archlinux.org/index.php/Netctl#Installation
  pacman_sync dialog || die "Couldn't install 'dialog'."
fi

if test_to_agree "Do install bluetooth utilites (bluez, bluez-utils)?"; then
  # https://wiki.archlinux.org/index.php/bluetooth#Installation
  pacman_sync bluez bluez-utils || die "Couldn't install Bluetooth tools."
  systemctl_permanently_start bluetooth.service \
    || die "Couldn't start 'bluetooth.service'."
fi

# https://wiki.archlinux.org/index.php/General_recommendations#Clock_synchronization
print_subsection "Clock synchronization"
# https://wiki.archlinux.org/index.php/Systemd-timesyncd#Usage
timedatectl set-ntp true || die "Couldn't enable NTP."

# https://wiki.archlinux.org/index.php/general_recommendations#DNS_security
print_subsection "DNS security"
# https://wiki.archlinux.org/index.php/DNSSEC#Install_a_DNSSEC-aware_validating_recursive_server
# https://wiki.archlinux.org/index.php/Dnsmasq#Installation
pacman_sync dnsmasq
# https://wiki.archlinux.org/index.php/Dnsmasq#Configuration
sed --in-place '$ s/#\(conf-dir=\)/\1/' /etc/dnsmasq.conf \
  || "Couldn't patch '/etc/dnsmasq.conf'."
readonly DNSMASQ_CONF_DIR_PATH=/etc/dnsmasq.d
mkdir --parent "${DNSMASQ_CONF_DIR_PATH}"
cat <<EOF > "${DNSMASQ_CONF_DIR_PATH}/dns-proxy.conf"
listen-address=::1,127.0.0.1
cache-size=1000
resolv-file="${DNSMASQ_CONF_DIR_PATH}/openresolv.nameservers"
# Enable DNSSEC
# uncomment to enable DNSSEC if resolver is supporting it
#dnssec
dnssec-check-unsigned
conf-file=/usr/share/dnsmasq/trust-anchors.conf
EOF
# https://wiki.archlinux.org/index.php/Dnsmasq#openresolv
sed --in-place '/\(name_servers\|dnsmasq_conf\|dnsmasq_resolv\)=/ d' \
  /etc/resolvconf.conf
cat <<EOF >> /etc/resolvconf.conf
name_servers="::1 127.0.0.1"
dnsmasq_conf="${DNSMASQ_CONF_DIR_PATH}/dnsmasq-openresolv.conf"
dnsmasq_resolv="${DNSMASQ_CONF_DIR_PATH}/openresolv.nameservers"
EOF
resolvconf -u
systemctl_permanently_start dnsmasq.service \
  || die "Couldn't start 'dnsmasq.service'."

# https://wiki.archlinux.org/index.php/Network_configuration#Check_the_connection
ping -c1 archlinux.org || die "Couldn't ping 'archlinux.org'."

# https://wiki.archlinux.org/index.php/general_recommendations#Setting_up_a_firewall
# https://wiki.archlinux.org/index.php/Security#Firewalls
print_subsection "Setting up a firewall"
# https://wiki.archlinux.org/index.php/nftables#Installation
pacman_sync nftables || die "Couldn't install 'nftables'."
# https://wiki.archlinux.org/index.php/nftables#Configuration
sed --in-place '
  # https://wiki.archlinux.org/index.php/nftables#Limit_rate_IPv4.2FIPv6_firewall
  s/tcp dport ssh .*/tcp dport ssh ct state new limit rate 15\/minute accept/

  # https://www.cups.org/doc/network.html#SNMP
  # remove old SNMP settings
  /# allow SNMP Manager/,/^$/ d
  # add new SNMP settings
  /# everything else/ i\
    # allow SNMP Manager\
    #udp sport snmp accept\
    #udp dport snmp-trap accept\n

  # https://wiki.archlinux.org/index.php/avahi#Firewall
  # remove old mDNS settings
  /# allow mDNS/,/^$/ d
  # add new mDNS settings
  /# everything else/ i\
    # allow mDNS\
    #ip daddr 224.0.0.251 udp dport mdns accept\
    #ip6 daddr ff02::fb udp dport mdns accept\n
' /etc/nftables.conf || "Couldn't patch '/etc/nftables.conf'."
# https://wiki.archlinux.org/index.php/nftables#Usage
systemctl_permanently_start nftables.service \
  || die "Couldn't start 'nftables.service'."

# https://wiki.archlinux.org/index.php/general_recommendations#Resource_sharing
print_subsection "Resource sharing"
if test_to_agree "Do install smbclient?"; then
  # https://wiki.archlinux.org/index.php/Samba#Client
  pacman_sync smbclient || die "Couldn't install 'smbclient'."
  mkdir --parent /etc/samba
  touch /etc/samba/smb.conf
fi
