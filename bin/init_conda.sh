#!/bin/bash
# init_conda.sh
#
# Description:
#   Initializes Conda by using shell script (conda.sh) from miniconda3.
#   Note: does not activate base environment or add conda to path -- see
#   addpath_conda.sh.
#
# Contact:      wu.kevi@northeastern.edu
# Last Updated: May 24, 2025

# Enable diagnostic output
_diag_init_conda() {
    FILE_NAME=init_conda.sh
    [[ "${DIAG,,}" =~ ^(true|1)$ ]] || return # check DIAG=true or 1
    echo "[DIAG] ($FILE_NAME) $*"
}

# Check if already initialized
if ! command -v conda &> /dev/null
then
	# Set DEV_PATH
	BIN_DIR="$(dirname "${BASH_SOURCE[0]}")" # relative
	BIN_DIR="$(cd $BIN_DIR && pwd)" # absolute
	_diag_init_conda "BIN_DIR set to: $BIN_DIR"
	if [[ -f "${BIN_DIR}/get_dev_path.sh" ]]; then
		source "${BIN_DIR}/get_dev_path.sh" # sets DEV_PATH
	else
		echo "ERROR: get_dev_path.sh not found in $BIN_DIR"
	fi

	# Set conda.sh
	CONDA_SH="${DEV_PATH}/software/miniconda3/etc/profile.d/conda.sh"
	_diag_init_conda "CONDA_SH set to: $CONDA_SH"

	# Ensure conda.sh exists
	if [ -f $CONDA_SH ]; then
		. $CONDA_SH
	else
		echo "Error: Unable to find $CONDA_SH"
	fi

	# Clean up temporary variables
	unset BIN_DIR
	unset CONDA_SH
	unset -f _diag_init_conda
else
	echo "Conda is already initialized in this shell"
fi