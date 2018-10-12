# https://wiki.archlinux.org/index.php/general_recommendations#Networking

source common.sh

print_section "Networking"

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
# dhcpcd can owerwrite 'resolv.conf'
# https://wiki.archlinux.org/index.php/Dhcpcd#resolv.conf
systemctl stop dhcpcd.service
systemctl disable dhcpcd.service

# https://wiki.archlinux.org/index.php/systemd-resolved#Configuration
ln --symbolic --force /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
systemctl_permanently_start systemd-resolved.service \
  || die "Couldn't start 'systemd-resolved.service'."

# https://wiki.archlinux.org/index.php/systemd-resolved#Automatically
# https://wiki.archlinux.org/index.php/NetworkManager#Installation
pacman_sync networkmanager || die "Couldn't install 'networkmanager'."
# https://wiki.archlinux.org/index.php/NetworkManager#Enable_NetworkManager
systemctl_permanently_start NetworkManager.service \
  || die "Couldn't start 'NetworkManager.service'."

# https://wiki.archlinux.org/index.php/Network_configuration#Check_the_connection
ping -c1 archlinux.org || die "Couldn't ping 'archlinux.org'."

# https://wiki.archlinux.org/index.php/NetworkManager#Using_Gnome-Keyring
# https://wiki.archlinux.org/index.php/GNOME/Keyring#Installation
pacman_sync gnome-keyring || die "Couldn't install 'gnome-keyring'."
# https://wiki.archlinux.org/index.php/GNOME/Keyring#PAM_method
gawk --include inplace '
  BEGIN {
      auth_rule = "auth       optional     pam_gnome_keyring.so"
      session_rule = "session    optional     pam_gnome_keyring.so auto_start"
  }

  # remove old rules for "pam_gnome_keyring.so"
  /\ypam_gnome_keyring\.so\y/ { next }

  ($1 == "account" || $1 == "password" || $1 == "session") && auth_rule != "" {
      print auth_rule; auth_rule = ""
  }
  { print }
  ENDFILE {
      if (auth_rule != "") print auth_rule
      print session_rule
  }
' /etc/pam.d/login || die "Couldn't patch '/etc/pam.d/login'."
gawk --include inplace '
  BEGIN {
      password_rule = "password	optional	pam_gnome_keyring.so"
  }

  # remove old rules for "pam_gnome_keyring.so"
  /\ypam_gnome_keyring\.so\y/ { next }

  $1 == "session" && password_rule != "" {
      print password_rule; password_rule = ""
  }
  { print }
  ENDFILE {
      if (password_rule != "") print password_rule
  }
' /etc/pam.d/passwd || die "Couldn't patch '/etc/pam.d/passwd'."

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
