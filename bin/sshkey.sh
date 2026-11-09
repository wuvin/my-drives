#!/bin/bash
# sshkey.sh
#
# Description:
#   Initializes SSH agent and add key.
#
# Contact:      wu.kevi@northeastern.edu
# Last Updated: November 09, 2026

# Check if sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	echo "ERROR: Script must be sourced." >&2
	echo "Usage: source ${0} <PATH>" >&2
	exit 1
fi

# Set local functions
_diag_sshkey() {  # diagnostic display
    [[ "${DIAG,,}" =~ ^(true|1|yes)$ ]] || return # check DIAG=true
    echo "[DIAG] (sshkey.sh) $*"
}

_resolve_ssh_path() (  # run in subshell so shopt changes not in shell
	shopt -s nullglob dotglob
	local input="$1" 
	local current name err
	local -a parts matches

	if [[ "$input" == /* ]]; then
		current="/";
	else
		current=".";
	fi
	IFS='/' read -r -a parts <<< "$input"

	for part in "${parts[@]}"; do
		[[ -z "$part" || "$part" == "." ]] && continue

		# Prioritize exact match or ".." over c-i matching
		if [[ "$part" == ".." || -e "${current%/}/$part" ]]; then
			current="${current%/}/$part"
			continue
		fi

		# Search for c-i matches
		matches=()
		for entry in "${current%/}"/*; do
			name="${entry##*/}"
			[[ "${name,,}" == "${part,,}" ]] && matches+=("$entry")
		done

		# Error if unable to resolve unique path
		if (( ${#matches[@]} > 1 )); then
			err="'$part': ${matches[*]##*/}"
			echo "ERROR: Ambiguous case-insensitive match for $err" >&2
			return 1
		elif (( ${#matches[@]} == 0 )); then
			return 1
		fi

		# Set
		current="${matches[0]}"
	done

	[[ "$current" == ./* ]] && current="${current#./}"
	printf '%s\n' "$current"
)

# Check SSH_AUTH_SOCK
if { [ ! -z "$SSH_AUTH_SOCK" ] && [ ! -z "$SSH_AGENT_PID" ]; }; then
	echo "ERROR: Existing agent (SOCK=$SSH_AUTH_SOCK, PID=$SSH_AGENT_PID)"
	echo 'Use `eval "$(ssh-agent -k)"` to kill before adding another key'
	echo 'Check existing keys with `ssh-add -L`'
	return
fi

# Check for other ssh-agent processes running
TMP_SSH=$(ls /tmp -maxdepth 1 -name 'ssh-*' -user "$USER" 2>/dev/null)
if [ ! -z "$TMP_SSH" ]; then
	echo "ERROR: Existing ssh processes within /tmp: $TMP_SSH"
fi
PID_SSH=$(pgrep -u "$USER" -x ssh-agent)
if [ ! -z "$PID_SSH" ]; then
	echo "ERROR: Active ssh-agent processes with PID: $PID_SSH"
fi
if { [ ! -z "$TMP_SSH" ] || [ ! -z "$PID_SSH" ]; }; then
	unset TMP_SSH
	unset PID_SSH
	echo "Terminate active processes and try again"
	return
fi
unset TMP_SSH
unset PID_SSH

# Read arg input into SSH_KEY, if provided
if [ ! -z "$SSH_KEY" ]; then
	echo "ERROR: Variable SSH_KEY appears to already be set: $SSH_KEY"
	echo "Terminate and try again"
	return
fi
[ ! -z "$1" ] && SSH_KEY=$1

# Read in SSH_KEY as path to key
if [[ -z "$SSH_KEY" ]]; then
	read -p "Enter SSH key: " SSH_KEY
fi

# Expand leading ~
if [[ "$SSH_KEY" == "~" || "$SSH_KEY" == "~/"* ]]; then
	_diag_sshkey "Expanding '$SSH_KEY' to '$HOME${SSH_KEY:1}'"
	SSH_KEY="$HOME${SSH_KEY:1}"
else
	_diag_sshkey "SSH_KEY set to: $SSH_KEY"
fi

# Check exact path, then, if needed, case-insensitive match
if [[ ! -f "$SSH_KEY" ]]; then
	_diag_sshkey "Failed to find input path. Attempting to resolve..."
	SSH_KEY="$(_resolve_ssh_path $SSH_KEY)"
	if [[ ! -f "$SSH_KEY" ]]; then
		echo "ERROR: Unable to resolve path to SSH key."
		return 1
	fi
	_diag_sshkey "Resolved to: $SSH_KEY"
fi

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
	_diag_sshkey "Triggered NTFS check: $KEY_FSTYPE"
	load_ntfs_ssh_key "$SSH_KEY"
	unset -f _diag_sshkey
	unset SSH_KEY
	unset KEY_FSTYPE
	return
fi
unset KEY_FSTYPE
unset -f load_ntfs_ssh_key

# Set relative to DEV_PATH if needed
if [[ ! -f "${SSH_KEY}" ]]; then
	unset -f _diag_sshkey
	unset BIN_DIR
	echo "$SSH_KEY: No such file or directory"
	unset SSH_KEY
	return
fi

# >>> ssh >>>
eval "$(ssh-agent -s)"
ssh-add "$SSH_KEY"
# <<< ssh <<<

# Clear temporary variables
unset -f _diag_sshkey _resolve_ssh_path
unset SSH_KEY
unset BIN_DIR
