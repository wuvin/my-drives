#!/bin/bash
# add_ssh.sh
#
# Description:
#   Initializes SSH agent and add key.
#
# Contact:      wu.kevi@northeastern.edu
# Last Updated: July 18, 2025

# Check SSH_AUTH_SOCK
if { [ ! -z "$SSH_AUTH_SOCK" ] && [ -z "$SSH_AGENT_PID" ]; }; then
	echo "ERROR: Variable SSH_AUTH_SOCK is already set: $SSH_AUTH_SOCK"
	echo "Clear before attempting to run ssh-agent"
	return
elif [ ! -z "$SSH_AUTH_SOCK" ]; then
	echo "ERROR: Existing agent (SOCK=$SSH_AUTH_SOCK, PID=$SSH_AGENT_PID)"
	echo 'Use `eval "$(ssh-agent -k)"` to kill before adding another key'
	echo 'Check existing keys with `ssh-add -L`'
	return
fi

# Check for other ssh-agent processes running
TMP_SSH=$(ls /tmp | grep ssh-)
if [ ! -z "$TMP_SSH" ]; then
	echo "ERROR: Existing ssh processes within /tmp: $TMP_SSH"
fi
PID_SSH=$(ps aux | grep "\sssh-agent -s" | awk '{print $2}')
if [ ! -z "$PID_SSH" ]; then
	echo "ERROR: Active ssh-agent processes with PID: $PID_SSH"
fi
if { [ ! -z "$TMP_SSH" ] || [ ! -z "$PID_SSH" ]; }; then
	unset TMP_SSH
	unset PID_SSH
	echo "Clear active processes and try again"
	return
fi
unset TMP_SSH
unset PID_SSH

# Read input into SSH_KEY, if provided
if [ ! -z "$SSH_KEY" ]; then
	echo "ERROR: Variable SSH_KEY appears to already be set: $SSH_KEY"
	echo "Clear and try again"
	return
fi
[ ! -z "$1" ] && SSH_KEY=$1

# Enable diagnostic output
_diag_add_ssh() {
    [[ "${DIAG,,}" =~ ^(true|1|yes)$ ]] || return # check DIAG=true
    echo "[DIAG] (add_ssh.sh) $*"
}

# Check SSH_KEY
if [[ -z "$SSH_KEY" ]]; then
	read -p "Enter SSH key: " SSH_KEY
fi
SSH_KEY="${SSH_KEY,,}" # case-insensitive
SSH_KEY="${SSH_KEY/#~/$HOME}" # set home directory where necessary
_diag_add_ssh "SSH_KEY set to: $SSH_KEY"

# Define different function for NTFS partition
load_ntfs_ssh_key() {
	local original_key="$1"
	local temp_key="/tmp/${original_key##*/}"
	
	if [ ! -f "$original_key" ]; then
		echo "ERROR: Key file not found ($original_key)"
		return
	fi
	
	# Copy key to temp location
	cp "$original_key" "$temp_key"
	
	# Set secure permissions
	chmod 600 "$temp_key"
	
	# Load into ssh-agent
	eval "$(ssh-agent -s)"
	ssh-add "$temp_key"
	local result=$?
	
	# Securely delete temp key
	shred -u "$temp_key" 2>/dev/null || rm -f "$temp_key"
	
	if [ $result -eq 0 ]; then
		echo "Key from NTFS partition loaded successfully into ssh-agent"
	else
		echo "Failed to load key from NTFS partition into ssh-agent"
	fi
	
	return $result
}

# Use different function if SSH_KEY is on an NTFS partition
KEY_FSTYPE="$(findmnt -n -o FSTYPE --target "$SSH_KEY")"
if { [ "$KEY_FSTYPE" == "ntfs" ] || [ "$KEY_FSTYPE" == "ntfs3" ] || \
     [ "$KEY_FSTYPE" == "fuseblk" ]; }; then
	_diag_add_ssh "Triggered NTFS check: $KEY_FSTYPE"
	load_ntfs_ssh_key "$SSH_KEY"
	unset -f _diag_add_ssh
	unset SSH_KEY
	unset KEY_FSTYPE
	return
fi
unset KEY_FSTYPE
unset -f load_ntfs_ssh_key

# Set relative to DEV_PATH if needed
if [[ ! -f "${SSH_KEY}" ]]; then
	echo WHAT
	echo "Could not find ${SSH_KEY}"
	TEMP=$SSH_KEY
	unset SSH_KEY
	return
	BIN_DIR="$(dirname "${BASH_SOURCE[0]}")" # relative
	BIN_DIR="$(cd $BIN_DIR && pwd)" # absolute
	_diag_add_ssh "BIN_DIR set to: $BIN_DIR"
	
	if [[ -f "${BIN_DIR}/get_dev_path.sh" ]]; then
		source "${BIN_DIR}/get_dev_path.sh" # sets DEV_PATH
	else
		echo "$BIN_DIR/get_dev_path.sh: No such file or directory"
	fi
	
	SSH_KEY="$DEV_PATH/config/.ssh/$SSH_KEY"
	_diag_add_ssh "Reset SSH_KEY to: $SSH_KEY"
fi
if [[ ! -f "${SSH_KEY}" ]]; then
	unset -f _diag_add_ssh
	unset BIN_DIR
	echo "$SSH_KEY: No such file or directory"
	return
fi

# >>> ssh >>>
eval "$(ssh-agent -s)"
ssh-add $SSH_KEY
# <<< ssh <<<

# Clear temporary variables
unset -f _diag_add_ssh
unset SSH_KEY
unset BIN_DIR
