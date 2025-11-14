#!/bin/bash
set -euo pipefail

# --- Reusable Helper Functions ---

# A generic function to display a menu and get user's choice.
# Arguments:
#   $1: The prompt to display to the user.
#   $2+: The list of menu options.
select_menu() {
    local prompt="$1"
    shift
    local options=("$@")
    
    # PS3 is the prompt string for the select command.
    PS3="$prompt"
    select opt in "${options[@]}"; do
        if [[ -n "$opt" ]]; then
            echo "$opt"
            return
        else
            echo "Invalid choice. Please try again." >&2
        fi
    done
}

# Final execution function. Centralizes the sudo call.
run_setup() {
    local env="$1" os="$2" version="$3" setup_type="$4"
    local worker_arg="${5:-}" # Default to empty string if not provided
    local arch_arg="${6:-}"   # Default to empty string if not provided

    echo "Proceeding with ${env} setup for ${os} ${version}..."
    echo "Setup type: ${setup_type}"
    [[ -n "$worker_arg" ]] && echo "Worker size: ${worker_arg#-}"
    [[ -n "$arch_arg" ]] && echo "Architecture flag: ${arch_arg#-}"
    
    # Use an array for safer argument passing
    local script_args=("${os}" "${version}" "${worker_arg}" "${arch_arg}" "${setup_type}")

    # The script to be run inside the new shell.
    # It sources the target script and passes along all of its own arguments ("$@").
    local inner_script=""
    if (( ${#NAMED_ARGS[@]} > 0 )) && [[ "$env" == "lxd" ]]; then
        echo "Detected named arguments: ${NAMED_ARGS[*]}"
        echo "Passing named args to LXD script."
        inner_script=". 'scripts/${env}.sh' ${NAMED_ARGS[@]:+${NAMED_ARGS[@]}} \"\$@\""
    else
        inner_script=". 'scripts/${env}.sh' \"\$@\""
    fi

    # Execute using sudo bash -c.
    # The first argument after the script string ('bash') becomes $0 inside the new shell.
    # The subsequent arguments ("${script_args[@]}") become $1, $2, $3, etc.
    sudo bash -c "${inner_script}" bash "${script_args[@]}"
}


# --- Parameter Gathering Functions ---

# Get OS and Version from the user for a given environment.
get_os_details() {
    local env="$1"
    
    local os_options=()
    case "$env" in
        lxd)    os_options=("Ubuntu" "Back");;
        *)      os_options=("Ubuntu" "CentOS/AlmaLinux" "Back");;
    esac

    local os_choice
    os_choice=$(select_menu "Select the OS for $env setup: " "${os_options[@]}")

    case "$os_choice" in
        "Ubuntu")
            local version
            version=$(select_menu "Select Ubuntu version: " "24.04" "22.04" "Back")
            [[ "$version" == "Back" ]] && return 1
            echo "ubuntu $version"
            ;;
        "CentOS/AlmaLinux")
            local version
            version=$(select_menu "Select CentOS/AlmaLinux version: " "9" "Back")
            [[ "$version" == "Back" ]] && return 1
            echo "centos $version"
            ;;
        "Back")
            return 1
            ;;
    esac
}

# Determine the setup type (Minimal/Complete) based on environment and OS.
get_setup_type() {
    local env="$1" os="$2"

    if [[ "$os" == "centos" || "$env" == "docker" || "$env" == "podman" ]]; then
        echo "minimal" # These combinations only support minimal setup
        return
    fi
    
    # For VM or LXD on Ubuntu, ask the user
    local setup_choice
    setup_choice=$(select_menu "Choose setup type: " "Minimal" "Complete" "Back")

    case "$setup_choice" in
        "Minimal")  echo "minimal";;
        "Complete") echo "complete";;
        "Back")     return 1;;
    esac
}

# Get LXD-specific worker and architecture arguments.
get_lxd_args() {
    local worker_arg=""
    local worker_choice
    worker_choice=$(select_menu "Choose worker category: " "default" "2xlarge" "4xlarge")
    case "$worker_choice" in
        "2xlarge") worker_arg="-2xlarge";;
        "4xlarge") worker_arg="-4xlarge";;
    esac

    local arch_arg=""
    # More robust check for POWER10 CPU
    if grep -q -E 'cpu\s+:\s+POWER10' /proc/cpuinfo 2>/dev/null; then
        arch_arg="-p10"
    fi

    local export_img_choice
    export_img_choice=$(select_menu "Choose whether to export final image: " "yes" "no")
    case "$export_img_choice" in 
        "yes") NAMED_ARGS+=("--export-image");;
        "no") ;;
    esac
    
    LXD_ARGS=("$worker_arg" "$arch_arg")
}


# --- Main Logic ---

main() {
    while true; do
        # `|| true` prevents script exit if user presses Ctrl+D
        main_choice=$(select_menu "Select the setup type: " "VM (host machine)" "LXD" "Docker" "Podman" "Exit") || true

        local env=""
        local os_details=""
        local os=""
        local version=""
        local setup_type=""
        local lxd_args=""
        local worker_arg=""
        local arch_arg=""
        
        case "$main_choice" in
            "VM (host machine)")
                env="vm"
                # Source /etc/os-release for a reliable and efficient way to get OS info
                if [[ -f /etc/os-release ]]; then
                    # shellcheck source=/dev/null
                    . /etc/os-release
                    os=$(echo "$ID" | tr '[:upper:]' '[:lower:]')
                    version="$VERSION_ID"
                    echo "Detected Host OS: $os $version"
                    os_details="$os $version"
                else
                    echo "Could not detect OS from /etc/os-release. Please choose manually." >&2
                    # Fallback to manual selection
                    os_details=$(get_os_details "$env") || continue
                fi
                ;;

            "LXD"|"Docker"|"Podman")
                env=$(echo "$main_choice" | tr '[:upper:]' '[:lower:]')
                os_details=$(get_os_details "$env") || continue
                ;;

            "Exit")
                echo "Exiting."
                break
                ;;
            "") # Handles Ctrl+D from select menu
                echo "Exiting."
                break
                ;;
        esac

        # Parse os_details into os and version
        read -r os version <<< "$os_details"

        # Check architecture support
        local arch
        arch=$(uname -m)
        case "$arch" in
            ppc64le|s390x|x86_64)
                # Architecture is supported, proceed
                ;;
            *)
                echo "Architecture '$arch' is not supported." >&2
                local back_choice
                back_choice=$(select_menu "Choose an option: " "Return to main menu" "Exit")
                [[ "$back_choice" == "Exit" ]] && exit 0
                continue
                ;;
        esac

        # Get the setup type (Minimal/Complete)
        setup_type=$(get_setup_type "$env" "$os") || continue
        
        # Get extra args only if the environment is LXD
        if [[ "$env" == "lxd" ]]; then
            get_lxd_args
            read -r worker_arg arch_arg <<< "${LXD_ARGS[*]}"
        fi

        # Run the final setup
        run_setup "$env" "$os" "$version" "$setup_type" "$worker_arg" "$arch_arg"
        
        echo "Setup script finished."
        # Optional: Ask to continue or exit after a successful run
        local continue_choice
        continue_choice=$(select_menu "What next?" "Return to main menu" "Exit")
        if [[ "$continue_choice" == "Exit" ]]; then
            echo "Exiting."
            break
        fi

    done
}

# Declare global array to hold and parse named args
NAMED_ARGS=()
# Run the main function
main