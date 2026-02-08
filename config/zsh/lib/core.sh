#!/bin/bash
# Core shell utility library loader
# This file provides the core loading mechanism for the shell utility library

# Get the directory of this script
if [[ -n "$ZSH_LIB_DIR" ]]; then
    _SHELL_LIB_DIR="$ZSH_LIB_DIR"
elif [[ -n "$BASH_SOURCE" ]]; then
    _SHELL_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    _SHELL_LIB_DIR="$(cd "$(dirname "$0")" && pwd)"
fi

# Track loaded modules
if [[ -n "$BASH_VERSION" ]]; then
    declare -A _SHELL_LIB_LOADED
elif [[ -n "$ZSH_VERSION" ]]; then
    typeset -A _SHELL_LIB_LOADED
else
    # Fallback for other shells
    declare -A _SHELL_LIB_LOADED 2>/dev/null || true
fi

# Load a library module
shell::load() {
    local module="$1"
    local module_path="${_SHELL_LIB_DIR}/${module}.sh"
    
    # Check if already loaded (safely)
    if [[ -n "${_SHELL_LIB_LOADED[$module]:-}" ]]; then
        return 0
    fi
    
    # Try to load the module
    if [[ -f "$module_path" ]]; then
        source "$module_path"
        _SHELL_LIB_LOADED[$module]=1
        return 0
    else
        echo "Error: Module '$module' not found at: $module_path" >&2
        return 1
    fi
}

# Source a file if it exists
shell::source_if_exists() {
    local file="$1"
    [[ -f "$file" ]] && source "$file"
}

# Load vendor libraries
shell::load_vendor() {
    local vendor="$1"
    case "$vendor" in
        landau)
            shell::source_if_exists "${_SHELL_LIB_DIR}/vendor/landau-utils.sh"
            ;;
        bash-utility)
            # Load specific bash-utility modules
            local module="${2:-string}"  # Default to string module
            shell::source_if_exists "${_SHELL_LIB_DIR}/vendor/bash-utility/src/${module}.sh"
            ;;
        *)
            echo "Error: Unknown vendor '$vendor'" >&2
            return 1
            ;;
    esac
}

# Always load colors (needed by most other modules)
shell::load "colors"