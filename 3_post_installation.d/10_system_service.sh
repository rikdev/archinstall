# https://wiki.archlinux.org/index.php/general_recommendations#System_service

source common.sh

print_section "System service"

# https://wiki.archlinux.org/index.php/general_recommendations#Printing
print_subsection "Printing"
# https://wiki.archlinux.org/index.php/CUPS#Installation
pacman_sync cups{,-pdf} || die "Couldn't install printing utilites."
# https://www.cups-pdf.de/documentation.shtml#Installation
killall --quiet -- cupsd || true
# https://wiki.archlinux.org/index.php/CUPS#Socket_activation
systemctl enable --now org.cups.cupsd.socket \
  || die "Couldn't start 'org.cups.cupsd.socket'."
# https://wiki.archlinux.org/index.php/CUPS#CLI_tools
lpadmin \
  -p Virtual_PDF_Printer \
  -D 'Virtual PDF Printer' \
  -E \
  -v 'cups-pdf:/' \
  -m 'CUPS-PDF_noopt.ppd' \
  || die "Couldn't add or modify 'Virtual PDF Printer'."

lpadmin -d Virtual_PDF_Printer \
  || die "Couldn't set 'Virtual PDF Printer' as default printer."
