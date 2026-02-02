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
# Last Updated: November 26, 2025

_mount_point() {
    _diag_mount_point() {
        [[ "${DIAG,,}" =~ ^(true|1|yes)$ ]] || return # use if DIAG=true
        echo "[DIAG] (mount_point.sh) $*"
    }
    
    _display_vars() {
        if [[ ! -z "${!1}" ]]; then
            _diag_mount_point "$1 is set to ${!1}"
        fi
    }
   
    # Display environment variables being used
    _display_vars DRIVE_NAME
    _display_vars DRIVE_PATH
    _display_vars MOUNT_POINT
    
    # Locate shared drive
    local DRIVE_NAME="${DRIVE_NAME:-S-1TB-KJW3}"
    local DRIVE_PATH="${DRIVE_PATH:-/media/$USER/$DRIVE_NAME}"
    local MOUNT_POINT="${MOUNT_POINT:-/mnt/$DRIVE_NAME}"
    _diag_mount_point "DRIVE_NAME=$DRIVE_NAME"

    # Parse argin(1) into DRIVE_PATH
    if [ -z "$1" ]; then
        _diag_mount_point "Empty argin(1)"
    elif [ "$1" == "kwu" ]; then
        MOUNT_POINT="/mnt/kwu"
    elif [ -d "/media/$USER/$1" ]; then
        DRIVE_PATH="/media/$USER/$1"
    elif [ -d "$PWD/$1" ]; then
        DRIVE_PATH="$PWD/$1"
    elif [ -d "/media/$USER/$DRIVE_NAME/projects/$1" ]; then
        DRIVE_PATH="/media/$USER/$DRIVE_NAME/projects/$1"
        MOUNT_POINT="/mnt/$1"
    elif [ -d "/media/$USER/$DRIVE_NAME/dev/projects/$1" ]; then
        DRIVE_PATH="/media/$USER/$DRIVE_NAME/dev/projects/$1"
        MOUNT_POINT="/mnt/$1"
    elif [ ! -z "$1" ]; then
        echo "ERROR: Unknown input argument at position 1 ($1)"
        return 1
    fi
    _diag_mount_point "DRIVE_PATH=$DRIVE_PATH"
    _diag_mount_point "MOUNT_POINT=$MOUNT_POINT"
    
    # Parse argin(2) into mnt_folder toggle
#     if [[ "$(basename $(dirname $DRIVE_PATH))" == "projects" ]]; then
#         local mnt_foldername="${2:-true}" # default true if inside 'projects'
#     else
#         local mnt_foldername="${2:-false}" # default false else
#     fi
#     _diag_mount_point "mnt_foldername=$mnt_foldername"
#     if [[ "$mnt_foldername" != "true" && "$mnt_foldername" != "false" ]]; then
#         echo "ERROR: Unknown input argument at position 2 ($2)"
#         return 1
#     fi

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

_mount_point "$1"
