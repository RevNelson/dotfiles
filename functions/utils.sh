UTILS_ABSOLUTE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cmd_exists() {
    command -v $1 >/dev/null 2>&1
}

said_yes() {
    case "$1" in
    [Yy][Ee][Ss] | [Yy]) return 0 ;;
    *) return 1 ;;
    esac
}

apt_quiet() {
    DEBIAN_FRONTEND=noninteractive apt-get -yqq $* >/dev/null
}

# Load colors
. $UTILS_ABSOLUTE_PATH/colors.sh

error() {
    if [ $# -gt 1 ]; then
        FILENAME=$1
        shift
        echo -e $(red "$FILENAME: $*") >&2
    else
        echo -e $(red "$1") >&2
    fi
    exit 1
}

okay() {
    echo "$(green $1)"
}

run_as_root() {
    if [ -z $1 ]; then
        SCRIPT='Script'
    else
        SCRIPT=$1
    fi
    [ $EUID != "0" ] && error "$SCRIPT must be run as root."
    return 0
}

print_section() {
    BLNK=$(echo "$@" | sed 's/./#/g')
    echo -e "\n$(green $BLNK)"
    echo "$(green $@)"
    echo -e "\n$(green $BLNK)"
}
