#!/bin/bash

source "$SCRIPT_DIR/script/config.sh"
source "$SCRIPT_DIR/script/utils.sh"

ENV_FILE="$HOME/.story_env"

# Định nghĩa các mã màu
RESET='\033[0m'
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'

function check_env_wallet_info {
    clear
    print_simple_header
    echo -e "${BOLD}Environment and Wallet Information:${RESET}"
    echo "-----------------------------------"

    if [ -f "$ENV_FILE" ]; then
        echo -e "${BOLD}Story Installation Information:${RESET}"
        echo "-------------------------------"
        while IFS='=' read -r key value
        do
            if [[ $key != \#* ]]; then
                case $key in
                    "STORY_GETH_VERSION"|"STORY_VERSION")
                        echo -e "${BLUE}$key:${RESET} ${GREEN}$value${RESET}"
                        ;;
                    "INSTALL_DIR"|"STORY_GETH_BINARY"|"STORY_BINARY")
                        echo -e "${BLUE}$key:${RESET} ${YELLOW}$value${RESET}"
                        ;;
                    *)
                        echo -e "${BLUE}$key:${RESET} $value"
                        ;;
                esac
            fi
        done < "$ENV_FILE"
    else
        echo "ENV file not found. Story may not be installed."
    fi

    echo
    echo -e "${BOLD}Wallet Information:${RESET}"
    echo "-------------------"
    echo "This feature is under development."

    echo
    read -p "Press Enter to return to the main menu..."
}