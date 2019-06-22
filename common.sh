# Set paranoidal mode
set -eu
set -o pipefail

readonly KEYMAP='ruwin_cplk-UTF-8'
readonly FONT='UniCyrExt_8x16'
readonly SWAP_FILE_NAME='swapfile'

out() {
  local -r TEXT_COLOR="$1"
  local -r PREFIX="$2"
  local -r TEXT="$3"
  local -r PARAMETERS=("${@:4}")
  tput setaf "${TEXT_COLOR}"
  # shellcheck disable=SC2059
  printf "${PREFIX} ${TEXT}\\n" "${PARAMETERS[@]}"
  tput sgr0
}

print_section() {
  out 5 '\n#' "$@"
}

print_subsection() {
  out 5 '\n##' "$@"
}

print_error() {
  out 1 'ERROR:' "$@" >&2
}

die() {
  print_error "$@"
  exit 1
}

test_to_agree() {
  local -r TEXT="$1"
  # Clear stdin
  while read -r -t 0; do read -r; done
  read -r -p "${TEXT} (y,N) "
  [[ "${REPLY}" =~ ^[Yy]$ ]]
}

is_uefi_boot_mode() {
  ls /sys/firmware/efi/efivars >/dev/null 2>/dev/null
}

pacman_sync() {
  echo "Install package(s): $*"
  pacman --sync --noconfirm --needed "$@"
}

udevadm_reload() {
  udevadm control --reload && udevadm trigger
}
