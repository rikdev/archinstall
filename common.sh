set -o errexit -o nounset -o pipefail

readonly KEYMAP='ruwin_cplk-UTF-8'
readonly FONT='UniCyrExt_8x16'
readonly SWAP_FILE_NAME='swapfile'

out() {
	local -r LOCAL_TEXT_COLOR="$1"
	local -r LOCAL_PREFIX="$2"
	local -r LOCAL_TEXT="$3"
	local -r LOCAL_PARAMETERS=("${@:4}")
	[[ -f /dev/stdout ]] || tput setaf "${LOCAL_TEXT_COLOR}"
	# shellcheck disable=SC2059
	printf "${LOCAL_PREFIX} ${LOCAL_TEXT}\\n" "${LOCAL_PARAMETERS[@]}"
	[[ -f /dev/stdout ]] || tput sgr0
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
	local -r LOCAL_TEXT="$1"
	# Clear stdin
	while read -r -t 0; do read -r; done
	read -r -p "${LOCAL_TEXT} (y,N) "
	[[ "${REPLY}" =~ ^[Yy]$ ]]
}

retry() {
	local local_return_code=0
	for (( i=0; i<5; ++i )); do
		"$@" && return 0 || local_return_code="$?"
		sleep 1
	done
	return "${local_return_code}"
}

is_uefi_boot_mode() {
	ls /sys/firmware/efi/efivars >/dev/null 2>/dev/null
}

pacman_sync() {
	echo "Install package(s): $*"
	pacman --sync --noconfirm --needed "$@"
}

pacman_remove() {
	for package in "$@"; do
		echo "Removing package '${package}'"
		if pacman --query >/dev/null 2>/dev/null "${package}"; then
			pacman --noconfirm --remove --recursive "${package}" || return "$?"
		else
			echo "Package '${package}' was not found"
		fi
	done
}

udevadm_reload() {
	udevadm control --reload && udevadm trigger
}
