#!/bin/bash
# activate.d.sh
#
# Description:
#   Template of a shell script to execute following conda activation.  Place
#   inside desired environment:
#       ${CONDA_PREFIX}/etc/conda/activate.d/
#
#   This template changes the prompt modifier string from the default behavior.
#
# Contact:      wu.kevi@northeastern.edu
# Last Updated: July 24, 2025

# --- Functions ---

# _shorten_conda_prompt
#   For environment ENV, change prompt modifier either to '(*/ENV) ', if there
#   another environment with the same name located within the default env_dirs,
#   or '(ENV) ', otherwise.
_shorten_conda_prompt() {

    # Early return if env in default env_dirs, which should start with /
    if [[ ! "${CONDA_DEFAULT_ENV}" =~ ^/ ]]; then
        return
    fi

    # Get active environment name
    local env_name="$(basename "${CONDA_DEFAULT_ENV}")"

    # Append */ before env_name if there is an identical env in ENV_DIRS
    local -a envs_dirs
    readarray -t envs_dirs < <(conda config --show envs_dirs \
        | grep -E '^  -' \
        | sed 's/^  - //')
    local found_env=1 # false
    for dir in "${envs_dirs[@]}"; do
        [[ $found_env -eq 0 || -d "${dir}/${env_name}" ]]; found_env=$?
    done
    local env_mod="(${CONDA_DEFAULT_ENV})"
    if [[ $found_env -eq 0 ]]; then
        local new_mod="(*/${env_name})"
    else
        local new_mod="(${env_name})"
    fi
    CONDA_PROMPT_MODIFIER="${CONDA_PROMPT_MODIFIER/(*)/$new_mod}"
    export PS1="${PS1/$env_mod/$new_mod}"
}

# --- Main ---
_shorten_conda_prompt
