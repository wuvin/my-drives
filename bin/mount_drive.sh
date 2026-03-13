#!/bin/bash
# mount_drive.sh
#
# Description:
#   Create a bind mount for a shared drive.
#
# Usage:
#   source mount_drive.sh
#       Bind mounts /media/$USER/$DRIVE_NAME to /mnt/$DRIVE_NAME and CDs
#   source mount_drive.sh kwu
#       Bind mounts to /mnt/kwu instead
#   source mount_drive.sh project
#       Bind mounts /media/$USER/$DRIVE_NAME/projects/project to /mnt/project
#
# Contact:      wu.kevi@northeastern.edu
# Last Updated: March 13, 2025

_mount_point() {
    # Define helpful functions
    _diag_mount_point() {
        [[ "${DIAG,,}" =~ ^(true|1|yes)$ ]] || return # use if DIAG=true
        echo "[DIAG] (mount_point.sh) $*"
    }
    
    _display_vars() {
        if [[ ! -z "${!1}" ]]; then
            _diag_mount_point "$1 is set to ${!1}"
        fi
    }
    
    # Extract default drive name from absolute path of this script
    local SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
    local DEFAULT_DRIVE=$(echo "$SCRIPT_PATH" | cut -d'/' -f4)

    # Set variables to environment or to default
    local DRIVE_NAME="${DRIVE_NAME:-$DEFAULT_DRIVE}"
    DRIVE_NAME="${DRIVE_NAME:-S-1TB-KJW3}" # fallback
    local DRIVE_PATH="${DRIVE_PATH:-/media/$USER/$DRIVE_NAME}"
    local MOUNT_POINT="${MOUNT_POINT:-/mnt/$DRIVE_NAME}"
    local DIAG="${DIAG:-true}"
    
    # Parse arguments
    if [ -z "$1" ]; then
        _diag_mount_point "Empty argin(1)"
    elif [ "$1" == "kwu" ]; then
        MOUNT_POINT="/mnt/kwu"
    elif [ "$1" == "exc"  ]; then
        DRIVE_NAME="${DRIVE_NAME}-EXC"
        DRIVE_PATH="/media/$USER/$DRIVE_NAME"
        MOUNT_POINT="/mnt/exc/"
    elif [ -d "/media/$USER/$1" ]; then
        DRIVE_PATH="/media/$USER/$1"
    elif [ -d "$PWD/$1" ]; then
        DRIVE_PATH="$PWD/$1"
    elif [ -d "$DRIVE_PATH/projects/$1" ]; then
        DRIVE_PATH="$DRIVE_PATH/projects/$1"
        MOUNT_POINT="/mnt/$1"
    elif [ -d "$DRIVE_PATH/dev/projects/$1" ]; then
        DRIVE_PATH="$DRIVE_PATH/dev/projects/$1"
        MOUNT_POINT="/mnt/$1"
    elif [ ! -z "$1" ]; then
        echo "ERROR: Unknown input argument at position 1 ($1)"
        return 1
    fi
    
    # Display variable values
    _display_vars DRIVE_NAME
    _display_vars DRIVE_PATH
    _display_vars MOUNT_POINT

    # Check if drive exists
    if [ ! -d "$DRIVE_PATH" ]; then
        echo "ERROR: Unable to locate $DRIVE_PATH"
        return 1
    fi

    # Check if mount point exists
    if [ ! -d "$MOUNT_POINT" ]; then
        _diag_mount_point "Mount point not found.  Creating $MOUNT_POINT..."
        sudo mkdir -p "$MOUNT_POINT"
    fi
    
    # Set bind mount
    sudo mount -B "$DRIVE_PATH" "$MOUNT_POINT"
    _diag_mount_point "Mounted $DRIVE_PATH to $MOUNT_POINT"

    # Change directory
    if [[ "$PWD" == "$DRIVE_PATH"* ]]; then
        local REL_PATH="${MOUNT_POINT%/}${PWD##*$DRIVE_PATH}"
        cd "$REL_PATH"
        _diag_mount_point "Changed PWD to $REL_PATH"
    else
        cd "$MOUNT_POINT"
        _diag_mount_point "Changed PWD to $MOUNT_POINT"
    fi

    # Reverse touchpad scroll direction
    if [ -f "$MOUNT_POINT/bin/reverse_scroll.sh" ]; then
        echo "Run \`source $MOUNT_POINT/bin/reverse_scroll.sh\` if needed"
        #source $MOUNT_POINT/bin/reverse_scroll.sh
    fi
    
    return 0
}

_mount_point "$@"
