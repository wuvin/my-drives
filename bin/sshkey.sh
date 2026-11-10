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
	echo "ERROR: Script must be sourced to run in current terminal" >&2
	echo "Usage: source ${0} <PATH>" >&2
	exit 1  # terminates script when (mistakenly) run directly
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

_load_ntfs_ssh_key() {  # special case of key from NTFS partition
	local original_key="$1"
	local temp_key is_key_loaded

	# Use mktemp to create as 600 permission (NTFS cannot set to 600)
	temp_key="$(mktemp)" || { 
		echo "ERROR: Could not create temp file";
		return 1;
	}
	cat -- "$original_key" > "$temp_key"
	
	# Load into ssh-agent
	eval "$(ssh-agent -s)"
	ssh-add "$temp_key"
	is_key_loaded=$?
	
	# Securely delete temp key
	shred -u "$temp_key" 2>/dev/null || rm -f "$temp_key"
	
	# Return result
	if [ $is_key_loaded -eq 0 ]; then
		_diag_sshkey "Key from NTFS partition loaded into agent"
	else
		_diag_sshkey "Failed to load key from NTFS partition into agent"
	fi
	
	return $is_key_loaded
}

_scan_for_authsock_listener() {  # also avoids flagging forwarded case
	local stale_dirs alive_dirs agent_pids skip sock num_agents num_pids
	local found_alive=false  # ssh-add -l exits 0 if connects & has keys
                             #              ... 1 if connects & no keys
                             #              ... 2 if cannot connect
	local throw_err=false

	[[ "$SSH_AUTH_SOCK" == /tmp/ssh-*/* ]] && skip="${SSH_AUTH_SOCK%/*}"

    # Check agents
	while IFS= read -r -d '' dir; do
		# Ignore forwarded sessions (by skipping dir of SSH_AUTH_SOCK)
		if [[ "$dir" == "$skip" ]]; then
			_diag_sshkey "Skipping $dir (holds current SSH_AUTH_SOCK)"
			continue
		fi

		# Check if agent is listening
		#	Note: desktop agents (e.g., GNOME keyring runs `ssh-agent -D
		#		  -a ...`) do not match
		for sock in "$dir"/agent.*; do
            if [[ ! -S "$sock" ]]; then
                continue
            fi

			SSH_AUTH_SOCK="$sock" timeout 3 ssh-add -l >/dev/null 2>&1
            found_alive=$([[ $? -eq 0 || $? -eq 1 ]] && echo true)
            if $found_alive; then
                break
            fi
		done

        # Note active listeners
        [[ $found_alive ]] && alive_dirs+=("$dir")
        [[ ! $found_alive ]] && stale_dirs+=("$dir")
        _diag_sshkey "Found $dir (is_alive=$found_alive)"
	done < <(
		find /tmp \
			-maxdepth 1	\
			-type d \
			-name 'ssh-*' \
			-user "$(id -u)" \
			-print0 2>/dev/null
	)

    # Check PIDs
    while read -r pid; do
        [[ -n "$pid" ]] && agent_pids+=("$pid")
    done < <(
        pgrep \
            -u "$(id -u)" \
            -f '^ssh-agent( -[sc])?$'
    )

	# Throw error if stale agent found
	_diag_sshkey "Checking for stale agents..."
	(( ${#stale_dirs[@]} )) && (
		printf "Found stale agent directories in /tmp"
		printf " (no agent listening):\n"
		printf "    %s\n" ${stale_dirs[*]}
		printf "ERROR: Clear out stale agents before use\n"
		throw_err=true
	)

	# Note number of active agents and ssh-agent processes
	num_agents=${#alive_dirs[@]}
	(( $num_agents )) && (
		printf "Found active agent sockets in /tmp:\n"
		printf "    %s\n" ${alive_dirs[*]}
	)
	num_pids=${#agent_pids[@]}
	(( $num_pids )) && (
		printf "Found active ssh-agent processes with PID:\n"
		printf "    %s\n" ${agent_pids[*]}
	)

	# Connect to active agent in another terminal
	#   Note: assumes any active agent sockets in /tmp and corresponding
	#   	  ssh-agent process are from when user ran ssh-agent in some
	#		  other terminal, and that PID owns the socket
	_diag_sshkey \
		"Checking if another terminal has already run ssh-agent..."
	if [[ $num_agents != $num_pids ]]; then
		printf "ERROR: Mismatch between number of active agents and"
		printf " number of ssh-agent processes; resolve before"
		printf " continuing\n"
		throw_err=true
	elif [[ $num_agents > 1 ]]; then
		printf "ERROR: Unable to determine which ssh-agent to share"
		printf " among multiple active agents found; resolve before"
		printf " continuing\n"
		throw_err=true
	elif [[ $num_agents == 1 ]]; then  # connect to this agent
		sock=( "${alive_dirs[0]}"/agent.* )
		if [[ ${#sock[@]} != 1 ]]; then
			printf "ERROR: Expected 1 'agent.*' entry for socket but"
			printf " found %d\n" ${#sock[@]}
			throw_err=true
		else
			printf "Binding to existing socket at %s with PID %s...\n" \
				${sock} ${agent_pids[0]}
			export SSH_AUTH_SOCK="$sock"
			export SSH_AGENT_PID="${agent_pids[0]}"
		fi
	fi

	$throw_err
}

# Check if agent is already registered in shell
if [[ -n "$SSH_AUTH_SOCK" && -n "$SSH_AGENT_PID" ]]; then
    printf "ERROR: Existing agent in shell (SOCK=%s, PID=%s)\n" \
           $SSH_AUTH_SOCK $SSH_AGENT_PID
    printf "       Terminate before adding another key\n"
    printf "       Check existing keys with \`ssh-add -L\`\n"
	return 1
fi

# Check for other agents
if _scan_for_authsock_listener; then
	return 1  # function returns throw_err
elif [[ -n "$SSH_AGENT_PID" ]]; then
	printf "\nKey(s) loaded:\n"
	ssh-add -l
	return 0
fi

# Get path to key as arg passed
if [[ ! -z "$SSH_KEY" ]]; then  # avoid setting ahead of time
	echo "ERROR: Variable SSH_KEY should not already be set ($SSH_KEY)"
	return 1
fi
[[ ! -z "$1" ]] && SSH_KEY=$1  # path to key passed as arg

# Read in path to key, if needed
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

# Use workaround if SSH_KEY is on an NTFS partition
KEY_FSTYPE="$(findmnt -n -o FSTYPE --target "$SSH_KEY" 2>/dev/null)"
if { [ "$KEY_FSTYPE" == "ntfs" ] || [ "$KEY_FSTYPE" == "ntfs3" ] || \
     [ "$KEY_FSTYPE" == "fuseblk" ]; }; then
	_diag_sshkey "Triggered NTFS check: $KEY_FSTYPE"
	_load_ntfs_ssh_key "$SSH_KEY"
fi
unset KEY_FSTYPE

# >>> ssh >>>
eval "$(ssh-agent -s)"
ssh-add "$SSH_KEY"
# <<< ssh <<<

# Clear temporary variables
unset -f _diag_sshkey _resolve_ssh_path _load_ntfs_ssh_key \
         _scan_for_authsock_listener
unset SSH_KEY KEY_FSTYPE