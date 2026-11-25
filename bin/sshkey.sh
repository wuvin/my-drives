#!/bin/bash
# sshkey.sh
#
# Use `clear` flag to clean out stale agents or `clearall` for active as
# well as stale agents.
#
# Usage:
#	source sshkey.sh [-h|--help] [--clear] [--clearall] [--nodiag]
#	
#
# Description:
#   Initializes SSH agent and add key.
#
# Contact:      wu.kevi@northeastern.edu
# Last Updated: November 24, 2026

# Check if sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	echo "ERROR: Script must be sourced to run in current terminal" >&2
	echo "Usage: source ${0} <PATH>" >&2
	exit 1  # terminates script when (mistakenly) run directly
fi

# Set local functions
_diag_sshkey() {  # diagnostic display
    [[ "${DIAG,,}" =~ ^(true|1|yes)$ ]] || return 0 # check DIAG=true
    [[ "$1" == "-"* ]] && echo "$1" "[DIAG] (sshkey.sh) ${*:2}" >&2 \
		|| echo "[DIAG] (sshkey.sh) $*" >&2
}

_resolve_ssh_path() (  # run in subshell so shopt changes not in shell
	shopt -s nullglob dotglob
	local input="$1" 
	local current name err
	local -a parts matches
	local part entry  # declare local to avoid leakage after sourcing

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
	ssh-add "$temp_key"
	is_key_loaded=$?
	
	# Securely delete temp key
	shred -u "$temp_key" 2>/dev/null || rm -f "$temp_key"
	
	# Return result
	if [[ $is_key_loaded -eq 0 ]]; then
		_diag_sshkey "Key from NTFS partition loaded into agent"
	else
		_diag_sshkey "Failed to load key from NTFS partition into agent"
	fi
	
	return $is_key_loaded
}

_scan_for_authsock_listener() {  # also avoids flagging forwarded case
	local -n agent_pid="$1" alive_sock="$2" stale_sock="$3"
	local skip sock num_socket num_pid
	local found_alive  # ssh-add -l exits 0 if connects & has keys
                       #              ... 1 if connects & no keys
                       #              ... 2 if cannot connect
	local dir pid  # declare local to avoid leakage after sourcing
				    # ESPECIALLY for dir

	# Skip current socket in SSH_AUTH_SOCK
	[[ "$SSH_AUTH_SOCK" == /tmp/ssh-*/* ]] && skip="${SSH_AUTH_SOCK%/*}"

    # Check agents
	while IFS= read -r -d '' dir; do
		found_alive=false

		# Ignore forwarded sessions (by skipping dir of SSH_AUTH_SOCK)
		if [[ "$dir" == "$skip" ]]; then
			_diag_sshkey "Skipping $dir (holds current SSH_AUTH_SOCK)"
			continue
		fi

		# Check if agent is listening
		#	Note: desktop agents (e.g., GNOME keyring runs `ssh-agent -D
		#		  -a ...`) do not match
		for sock in "$dir"/agent.*; do
            [[ -S "$sock" ]] || continue  # skip if not socket

			SSH_AUTH_SOCK="$sock" timeout 3 ssh-add -l >/dev/null 2>&1
			(( $? < 2 )) && found_alive=true && break
		done

        # Note active listeners
        [[ $found_alive == true ]] && alive_sock+=("$dir") \
			|| stale_sock+=("$dir")
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
        [[ -n "$pid" ]] && agent_pid+=("$pid")
    done < <(
        pgrep \
            -u "$(id -u)" \
            -f '^ssh-agent( -[sc])?$'
    )
}

_find_key_in_dir() {  # $1=dir
	local match
	local expr="id_git*"
	local file  # declare local to avoid leakage after sourcing
	while IFS= read -r -d '' file; do
		if [[ -f "${file}.pub" ]]; then
			if [[ ! -z "$match" ]]; then
				echo "ERROR: Multiple possible keys found in $1" >&2
				return 1
			fi
			match="$file"
		fi
	done < <(
		find "$1" \
			-maxdepth 1	\
			-type f \
			-name "${expr}" \
			-user "$(id -u)" \
			-print0 2>/dev/null
	)
	if [[ -z "$match" ]]; then
		echo "ERROR: No key found in ${1}" >&2
		return 1
	fi
	printf "%s" "$match"  # is return 0 needed here?
}

_reset_this_terminal() {
	local xdg_keyring
	if [[ -S "$XDG_RUNTIME_DIR/keyring/ssh" ]]; then
		xdg_keyring="$XDG_RUNTIME_DIR/keyring/ssh"
	elif [[ -S "$XDG_RUNTIME_DIR/gcr/ssh" ]]; then
		xdg_keyring="$XDG_RUNTIME_DIR/gcr/ssh"
	fi
	if [[ -z "$xdg_keyring" ]]; then
		echo "ERROR: No XDG keyring found"
		return 1
	else
		_diag_sshkey "Resetting SSH_AUTH_SOCK" "from $SSH_AUTH_SOCK" \
					 "to $xdg_keyring"
		export SSH_AUTH_SOCK="$xdg_keyring"
		return 0
	fi
}

_clear_agents() {
	local -a pids alive stale holdout
	local ifailed=false
	local pid ii sock dir  # declare local to avoid leak after sourcing

	# Scan for listeners
	if ! _scan_for_authsock_listener pids alive stale; then
		return 1
	fi

	# Clear active agents
	if [[ "$1" == "clearall" ]]; then
		# Check own shell
		[[ -n "$SSH_AGENT_PID" ]] \
			&& [[ " ${pids[*]} " != *" $SSH_AGENT_PID "* ]] \
			&& [[ "$(ps -o comm= -p "$SSH_AGENT_PID" 2>/dev/null)" \
					== ssh-agent ]] \
			&& pids+=("$SSH_AGENT_PID")
		# SIGTERM kill found PIDs
		for pid in "${pids[@]}"; do
			_diag_sshkey "Stopping agent (PID $pid)"
			kill "$pid" 2>/dev/null
		done
		# Attempt to force any holdouts
		for ii in {1..10}; do
			holdout=()
			for pid in "${pids[@]}"; do  # still running
				[[ "$(ps -o stat= -p "$pid" 2>/dev/null)" =~ ^[^Z] ]] \
					&& holdout+=("$pid")
			done  # note: exited process awaiting clean up shows up as Z
			(( ${#holdout[@]} )) || break  # everyone exited; stop wait
			sleep 0.05  # 50ms; wait for agent(s) still shutting down
		done
		# SIGKILL holdouts
		for pid in "${holdout[@]}"; do
			_diag_sshkey "Agent (PID $pid) ignored SIGTERM;" \
				"sending SIGKILL"
			kill -9 "$pid" 2>/dev/null
		done
		# Rescan
		_diag_sshkey "Attempting rescan..."
		pids=() alive=() stale=()
		if ! _scan_for_authsock_listener pids alive stale; then
			return 1
		# Report active remaining
		elif (( ${#alive[@]} )); then
			echo "WARNING: Agents still active: ${alive[*]}"
			ifailed=true
		fi
	fi

	# Remove stale
	for sock in "${stale[@]}"; do
		[[ "$sock" == /tmp/ssh-* ]] || continue
		# Remove file content
		if [[ -d "$sock" ]]; then
			dir="$sock"
			rm -f -- "$dir"/agent.*
		else
			dir="${sock%/*}"
			[[ -S "$sock" ]] && rm -f -- "$sock"
		fi
		_diag_sshkey "Removed stale socket(s) in $dir"
		# Remove folder
		[[ "$dir" == /tmp/ssh-* ]] \
			&& ! rmdir -- "$dir" 2>/dev/null \
			&& [[ -d "$dir" ]] \
			&& echo "WARNING: Could not remove $dir" \
			&& ifailed=true
	done

	# Reset terminal if agent or socket no longer exists
	[[ -n "$SSH_AGENT_PID" ]] \
		&& ! kill -0 "$SSH_AGENT_PID" 2>/dev/null \
		&& unset SSH_AGENT_PID
	if [[ "$SSH_AUTH_SOCK" == /tmp/ssh-* \
			&& ! -S "$SSH_AUTH_SOCK" ]]; then
		unset SSH_AUTH_SOCK SSH_AGENT_PID
		_reset_this_terminal \
			|| _diag_sshkey "No keyring socket. SSH_AUTH_SOCK left unset"
	fi

	$ifailed && return 1
	return 0
}

# Main
_main() {
	# Check SSH_KEY
	if [[ ! -z "$SSH_KEY" ]]; then  # avoid setting ahead of time
		echo "ERROR: Var SSH_KEY should not already be set ($SSH_KEY)"
		return 1
	fi

	# Parse flags
	while [[ $# -gt 0 ]]; do
		case "$1" in
			-h|--help)
				echo "Usage: source ${BASH_SOURCE[0]} <dir_or_file>" \
					"[--clear|--clearall] [--nodiag]"
				return 1  # to indicate no key added
				;;
			--clear)
				_clear_agents
				return 1  # to indicate no key added
				;;
			--clearall)
				_clear_agents clearall
				return 1  # to indicate no key added
				;;
			--nodiag)
				DIAG=false;
				shift
				continue
				;;
			-*) echo "ERROR: Unknown flag ($1)" && return 1 ;;
			*) ;;
		esac
		if [[ ! -z "$SSH_KEY" ]]; then 
			echo "ERROR: Multiple positional arguments found";
			return 1
		fi
		SSH_KEY="$1"
		shift
	done

	# Check if agent is already registered in shell
	if [[ -n "$SSH_AUTH_SOCK" && -n "$SSH_AGENT_PID" ]]; then
		printf "ERROR: Existing agent in shell (SOCK=%s, PID=%s)\n" \
			$SSH_AUTH_SOCK $SSH_AGENT_PID
		printf "       Terminate before adding another key\n"
		printf "       Check existing keys with \`ssh-add -L\`\n"
		return 1
	fi

	# Scan for listeners
	local pids=() sockets=() stales=()
	local num_socket num_pid
	_scan_for_authsock_listener pids sockets stales
	num_socket=${#sockets[@]}
	(( $num_socket )) && (
		printf "Found active agent sockets in /tmp:\n"
		printf "    %s\n" ${sockets[*]}
	)
	num_pid=${#pids[@]}
	(( $num_pid )) && (
		printf "Found active ssh-agent processes with PID:\n"
		printf "    %s\n" ${pids[*]}
	)

	# Throw error if stale agent found
	_diag_sshkey "Checking for stale agents..."
	if (( ${#stales[@]} )); then
		printf "Found stale agent directories in /tmp"
		printf " (no agent listening):\n"
		printf "    %s\n" "${stales[@]}"
		printf "ERROR: Clear out stale agents before use"
		printf " (e.g., \`source ${BASH_SOURCE[0]} --clear\`)\n"
		return 1
	fi

	# Check for issues with agent(s) found
	#   Note: assumes any active agent sockets in /tmp and corresponding
	#   	  ssh-agent process are from when user ran ssh-agent in some
	#		  other terminal, and that PID owns the socket
	if [[ $num_socket != $num_pid ]]; then
		printf "ERROR: Mismatch between number of active agents and"
		printf " number of ssh-agent processes; resolve before"
		printf " continuing\n"
		return 1
	elif (( $num_socket > 1 )); then
		printf "ERROR: Unable to determine which ssh-agent to share"
		printf " among multiple active agents found; resolve before"
		printf " continuing\n"
		return 1
	fi

	# Share active agent, if available
	if [[ ! -z "$pids" && ! -z "$sockets" ]]; then
		sockets=( "${sockets[0]}"/agent.* )
		printf "Binding to existing socket at %s with PID %s...\n" \
				${sockets} ${pids[0]}
		export SSH_AUTH_SOCK="$sockets"
		export SSH_AGENT_PID="${pids[0]}"
		[[ -z "$SSH_KEY" ]] && return 0  # nothing new to add
	fi  # else, create new agent later

	# Get SSH_KEY
	if [[ -z "$SSH_KEY" ]]; then  # look in some default locations
		# Check some default locations
		if SSH_KEY=$(_find_key_in_dir "$PWD/.ssh" 2>/dev/null); then
			_diag_sshkey "Found key ${SSH_KEY##*/} in $PWD/.ssh"
		elif SSH_KEY=$(_find_key_in_dir "$PWD/../.ssh" 2>/dev/null); then
			_diag_sshkey "Found key ${SSH_KEY##*/} in $PWD/../.ssh"
		elif SSH_KEY=$(_find_key_in_dir "$HOME/.ssh" 2>/dev/null); then
			_diag_sshkey "Found key ${SSH_KEY##*/} in $HOME/.ssh"
		# Prompt user for path
		else
			read -erp "Enter SSH key: " SSH_KEY
			[[ -z "$SSH_KEY" ]] && {
				echo "ERROR: No key given"
				return 1
			}
		fi
	fi

	# Expand leading ~
	if [[ "$SSH_KEY" == "~" || "$SSH_KEY" == "~/"* ]]; then
		_diag_sshkey "Expanding '$SSH_KEY' to '$HOME${SSH_KEY:1}'"
		SSH_KEY="$HOME${SSH_KEY:1}"
	else
		_diag_sshkey "SSH_KEY set to: $SSH_KEY"
	fi

	# Check exact path, then, if needed, case-insensitive match
	if [[ ! -e "$SSH_KEY" ]]; then
		SSH_KEY="$(_resolve_ssh_path "$SSH_KEY")" || {
			echo "ERROR: Unable to resolve path to SSH key."
			return 1
		}
		_diag_sshkey "Resolved to: $SSH_KEY"
	fi 

	# Find key in folder if path is folder
	if [[ -d "$SSH_KEY" ]]; then
		SSH_KEY="$(_find_key_in_dir "$SSH_KEY")" || return 1
	fi

	# Throw error if ultimately unable to find key
	if [[ ! -f "$SSH_KEY" ]]; then
		echo "ERROR: \"$SSH_KEY\" is not a file or directory"
		return 1
	fi

	# Start agent, if needed and if no errors so far
	if [[ ! -n "$SSH_AGENT_PID" ]]; then
		eval "$(ssh-agent -s)"
	fi

	# Use workaround if SSH_KEY is on an NTFS partition
	local fs_type
	fs_type="$(findmnt -n -o FSTYPE --target "$SSH_KEY" 2>/dev/null)"
	if [[ "$fs_type" == "ntfs"?(3) || "$fs_type" == "fuseblk" ]]; then
		_diag_sshkey "Triggered NTFS check: $fs_type"
		_load_ntfs_ssh_key "$SSH_KEY"
	# Add key
	else
		ssh-add "$SSH_KEY"
	fi

	return
}

# Run
UNSET_DIAG=false
if [[ ! -n "$DIAG" ]]; then
	DIAG=true
	UNSET_DIAG=true
fi
if _main "$@"; then
	_diag_sshkey "Key(s) loaded:"
	[[ "${DIAG,,}" =~ ^(true|1|yes)$ ]] && ssh-add -l >&2
fi

# Clear temporary variables
if [[ "$UNSET_DIAG" == "true" ]]; then
	unset DIAG
fi
unset -f _diag_sshkey _resolve_ssh_path _load_ntfs_ssh_key \
         _scan_for_authsock_listener _find_key_in_dir \
		 _reset_this_terminal _clear_agents _main
unset SSH_KEY UNSET_DIAG