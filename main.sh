#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

export SCRIPT_DIR
source "$SCRIPT_DIR/script/config.sh"
source "$SCRIPT_DIR/script/utils.sh"

function display_main_menu() {
    clear
    print_ascii_art
    print_simple_header
    print_settings
    echo "Please choose an option:"
    echo "1/ Install Story - All-in-One Script"
    echo "2/ Start/Stop/Check/Remove Story Service"
    echo "3/ Story Tools"
    echo "4/ Secure Story Node"
    echo "5/ Check ENV & Wallet Info"
    echo "6/ Manage AIO Script"
    echo "7/ Exit"
    echo -n "Enter your choice [1-7]: "
}

function main_menu() {
    while true; do
        display_main_menu
        read choice
        case $choice in
            1) source "$SCRIPT_DIR/script/install.sh"; show_install_menu ;;
            2) source "$SCRIPT_DIR/script/service.sh"; story_service_menu ;;
            3) source "$SCRIPT_DIR/script/tools.sh"; story_tool_menu ;;
            4) source "$SCRIPT_DIR/script/security.sh"; security_story_menu ;;
            5) source "$SCRIPT_DIR/script/env.sh"; check_env_wallet_info ;;
            6) source "$SCRIPT_DIR/script/manage.sh"; manage_script ;;
            7) echo "Exiting..."; exit 0 ;;
            *) echo "Invalid option. Please try again." ;;
        esac
        echo "Press Enter to return to the main menu..."
        read
    done
}

# Start the main menu
main_menu