#!/bin/bash
# get_dev_path.sh
#
# Description:
#   Sets the environment variable DEV_PATH based on the location of this
#   script.  Path locates lowest-level or last dev folder.  For example,
#   if the script path is /home/usr001/tmp/dev/bin/get_dev_path.sh, then
#   DEV_PATH is set to /home/usr001/tmp/dev in the environment.
#
# Contact:      wu.kevi@northeastern.edu
# Last Updated: May 25, 2025

[ ! -z "$1" ] && DIAG=$1

# Enable diagnostic output
_diag_get_dev_path() {
    [[ "${DIAG,,}" =~ ^(true|1|yes)$ ]] || return # check DIAG=true
    echo "[DIAG] (get_dev_path.sh) $*"
}

# Get lowest `dev` folder in script directory
BIN_DIR="$(dirname "${BASH_SOURCE[0]}")"
BIN_DIR="$(cd $BIN_DIR && pwd)"
_diag_get_dev_path "BIN_DIR set to: $BIN_DIR"
if [[ "$BIN_DIR" == *"/dev/"* ]]; then
    DEV_PATH="${BIN_DIR%%/dev/*}/dev"
    _diag_get_dev_path "Found /dev/ in path. DEV_PATH set to: $DEV_PATH"
elif [[ "$BIN_DIR" == *"/dev" ]]; then
    DEV_PATH="$BIN_DIR"
    _diag_get_dev_path "Found trailing /dev. DEV_PATH set to: $DEV_PATH"
else
	echo "$BIN_DIR/dev: No such file or directory"
fi

# Clean up temporary variables
unset BIN_DIR
unset -f _diag_get_dev_path