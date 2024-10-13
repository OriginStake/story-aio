#!/bin/bash

source "$SCRIPT_DIR/script/config.sh"
source "$SCRIPT_DIR/script/utils.sh"

ENV_FILE="$HOME/.story_env"

# Load environment variables
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
else
    echo "Environment file not found. Please run the installation script first."
    exit 1
fi

# Define color codes
RESET='\033[0m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'

function start_story_service() {
    clear
    print_simple_header
    print_settings
    echo "Starting Story services..."
    if [[ "$OS_TYPE" == "linux" ]]; then
        sudo systemctl start story-geth
        sleep 3  # Đợi một chút để đảm bảo Story-Geth đã khởi động hoàn toàn
        sudo systemctl start story
        echo "Story services have been started."
    elif [[ "$OS_TYPE" == "macos" ]]; then
        echo "On macOS, you need to start the services manually in this order:"
        echo "1. Start Story-Geth:"
        echo "$STORY_GETH_BINARY --$CHAIN_ID --syncmode full --home $GETH_CONFIG_DIR --port $GETH_PORT &"
        echo "2. Wait for about 10 seconds, then start Story:"
        echo "$STORY_BINARY run --home $STORY_CONFIG_DIR &"
    fi
    read -p "Press Enter to continue..."
}

function stop_story_service() {
    clear
    print_simple_header
    print_settings
    echo "Stopping Story service..."
    if [[ "$OS_TYPE" == "linux" ]]; then
        sudo systemctl stop story-geth story
        echo "Story service has been stopped."
    elif [[ "$OS_TYPE" == "macos" ]]; then
        echo "On macOS, you need to stop the service manually:"
        echo "killall story-geth story"
    fi
    read -p "Press Enter to continue..."
}

function check_story_service_status() {
    clear
    print_simple_header
    print_settings
    echo "Checking Story service status..."
    if [[ "$OS_TYPE" == "linux" ]]; then
        # Function to get service status and logs
        get_service_status_and_logs() {
            local service=$1
            local status=$(systemctl is-active $service)
            local color=""
            case $status in
                "active") color="\e[32m" ;; # Green
                "inactive") color="\e[31m" ;; # Red
                *) color="\e[33m" ;; # Yellow for other states
            esac
            echo -e "${color}$service: $status\e[0m"
            
            # Get uptime if service is active
            if [ "$status" == "active" ]; then
                local uptime=$(systemctl show $service --property=ActiveEnterTimestamp | cut -d'=' -f2)
                echo "  Uptime: $(date -d "$uptime" +'%d days %H hours %M minutes')"
            fi

            # Get last 5 log lines
            echo "  Last 5 log lines:"
            journalctl -u $service -n 8 --no-pager | sed 's/^/    /'
            echo
        }

        get_service_status_and_logs "story-geth"
        get_service_status_and_logs "story"

    elif [[ "$OS_TYPE" == "macos" ]]; then
        echo "On macOS, checking service status:"
        
        check_process_and_logs() {
            local process_name=$1
            if pgrep -f "$process_name" > /dev/null; then
                echo -e "\e[32m$process_name: running\e[0m"
                echo "  PID: $(pgrep -f "$process_name")"
                echo "  Uptime: $(ps -o etime= -p $(pgrep -f "$process_name"))"
                echo "  Last 8 log lines:"
                log_file="/tmp/${process_name}.log"
                if [ -f "$log_file" ]; then
                    tail -n 8 "$log_file" | sed 's/^/    /'
                else
                    echo "    Log file not found. Make sure you're redirecting output to /tmp/${process_name}.log"
                fi
            else
                echo -e "\e[31m$process_name: not running\e[0m"
            fi
            echo
        }

        check_process_and_logs "story-geth"
        check_process_and_logs "story"
    fi
    read -p "Press Enter to continue..."
}

function remove_story_installations() {
    clear
    print_simple_header
    print_settings
    echo "You have chosen 'Remove all Story installations (CAUTION)'."
    echo "This action will delete all Story data. Are you sure you want to continue? (Yes/No):"
    read confirmation
    confirmation=$(echo "$confirmation" | tr '[:upper:]' '[:lower:]')

    if [[ "$confirmation" == "yes" ]]; then
        echo "Do you want to backup the following important data? (yes/no)"
        echo "1/ $STORY_DIR/story/config"
        echo "2/ $STORY_DIR/story/node_key.json"
        echo "3/ $STORY_DIR/story/priv_validator_key.json"
        echo "4/ $STORY_DIR/data/priv_validator_state.json"
        read backup_confirmation
        backup_confirmation=$(echo "$backup_confirmation" | tr '[:upper:]' '[:lower:]')

        if [[ "$backup_confirmation" == "yes" ]]; then
            BACKUP_DIR="$HOME/story-backup-$(date +%Y%m%d_%H%M%S)"
            mkdir -p "$BACKUP_DIR"
            echo "Backing up important files to $BACKUP_DIR..."
            cp -r "$STORY_DIR/story/config" "$BACKUP_DIR/" 2>/dev/null
            cp "$STORY_DIR/story/node_key.json" "$BACKUP_DIR/" 2>/dev/null
            cp "$STORY_DIR/story/priv_validator_key.json" "$BACKUP_DIR/" 2>/dev/null
            cp "$STORY_DIR/data/priv_validator_state.json" "$BACKUP_DIR/" 2>/dev/null
            echo "Backup completed."
        fi

        echo "Removing all Story installations..."

        # Stop services
        if [[ "$OS_TYPE" == "linux" ]]; then
            echo "Stopping Story services on Linux..."
            sudo systemctl stop story-geth story
            echo "Disabling Story services..."
            sudo systemctl disable story-geth story
            echo "Removing service files..."
            sudo rm -f /etc/systemd/system/story-geth.service /etc/systemd/system/story.service
            echo "Reloading systemd..."
            sudo systemctl daemon-reload
        elif [[ "$OS_TYPE" == "macos" ]]; then
            echo "Stopping Story services on macOS (if running)..."
            killall story-geth story 2>/dev/null
        fi

        # Remove binaries
        echo "Removing Story binaries..."
        sudo rm -f "$STORY_GETH_BINARY" "$STORY_BINARY"
        sudo rm -f /usr/local/bin/story-geth /usr/local/bin/story
        sudo rm -f /usr/bin/story-geth /usr/bin/story
        sudo rm -f $HOME/go/bin/story-geth $HOME/go/bin/story

        # Remove from PATH
        echo "Removing Story from PATH..."
        sed -i '/story/d' $HOME/.bashrc
        sed -i '/story/d' $HOME/.bash_profile
        sed -i '/story/d' $HOME/.profile

        # Remove data directories
        echo "Removing Story data directories..."
        rm -rf "$STORY_DIR"

        # Remove environment file
        rm -f "$ENV_FILE"

        echo "All Story installations have been removed."
        if [[ "$backup_confirmation" == "yes" ]]; then
            echo "Important files have been backed up to $BACKUP_DIR"
        fi

        # Remind user to restart shell
        echo "Please restart your shell or run 'source ~/.bashrc' to apply PATH changes."
    else
        echo "Removal cancelled."
    fi
    read -p "Press Enter to continue..."
}

function check_service_status() {
    local service_name=$1
    if [[ "$OS_TYPE" == "linux" ]]; then
        systemctl is-active --quiet $service_name && echo "Active" || echo "Inactive"
    elif [[ "$OS_TYPE" == "macos" ]]; then
        pgrep -f $service_name > /dev/null && echo "Active" || echo "Inactive"
    fi
}

function story_service_menu() {
    local first_run=true
    while true; do
        clear
        print_simple_header
        print_settings

        story_status=$(check_service_status "story")
        story_geth_status=$(check_service_status "story-geth")
        
        if $first_run; then
            echo "Installation completed successfully!"
            echo "You can now start the Story service."
            echo
            first_run=false
        fi

        printf "${BLUE}%-20s${RESET} %s\n" "Story Service:" "$story_status"
        printf "${BLUE}%-20s${RESET} %s\n" "Story GETH:" "$story_geth_status"
        echo "-------------------------------------------------------"
        get_sync_info
        echo "-------------------------------------------------------"
        echo

        echo "Choose an option:"
        echo "1/ Start Story Service"
        echo "2/ Stop Story Service"
        echo "3/ Check Story Service Status"
        echo "4/ Remove all Story installations (CAUTION)"
        echo "5/ Refresh Sync Info"
        echo "6/ Return to previous menu"
        echo -n "Enter your choice [1-6]: "
        read choice

        case $choice in
            1) start_story_service ;;
            2) stop_story_service ;;
            3) check_story_service_status ;;
            4) remove_story_installations ;;
            5) continue ;;  # This will refresh the menu and sync info
            6) return ;;
            *) echo "Invalid option. Please try again." ;;
        esac
    done
}

# Uncomment the line below if you want to run the menu directly from this script
# story_service_menu

function print_settings() {
    clear
    print_simple_header
    echo "----------------------------------------------------------------"
    
    if [ -f "$ENV_FILE" ]; then
        while IFS='=' read -r key value
        do
            if [[ $key != \#* ]]; then
                case $key in
                    STORY_GETH_VERSION|STORY_VERSION)
                        printf "${CYAN}%-20s${RESET} ${CYAN}%s${RESET}\n" "$key:" "$value"
                        ;;
                    CHAIN_ID|MONIKER)
                        printf "${BLUE}%-20s${RESET} ${CYAN}%s${RESET}\n" "$key:" "$value"
                        ;;
                    STORY_GETH_BINARY|STORY_BINARY)
                        # Tìm vị trí thực tế của binary
                        local actual_location=$(which $(basename $value))
                        if [ -n "$actual_location" ]; then
                            printf "${BLUE}%-20s${RESET} ${YELLOW}%s${RESET}\n" "$key:" "$actual_location"
                        else
                            printf "${BLUE}%-20s${RESET} ${YELLOW}%s ${RED}(not found)${RESET}\n" "$key:" "$value"
                        fi
                        ;;
                    INSTALL_DIR|STORY_DIR|BACKUP_DIR|INSTALL_LOG)
                        printf "${BLUE}%-20s${RESET} ${YELLOW}%s${RESET}\n" "$key:" "$value"
                        ;;
                    *)
                        printf "${BLUE}%-20s${RESET} %s\n" "$key:" "$value"
                        ;;
                esac
            fi
        done < "$ENV_FILE"
    else
        echo "Environment file not found. Please run the installation script first."
    fi

    echo "----------------------------------------------------------------"
}

function print_info() {
    local key=$1
    local value=$2
    local color=${!3:-$BLUE}
    printf "${color}%-20s${RESET} %s\n" "$key:" "$value"
}

function get_sync_info() {
    local rpc_port=$(grep -m 1 -oP '^laddr = "\K[^"]+' "$STORY_DIR/story/config/config.toml" | cut -d ':' -f 3)
    local local_height=$(curl -s localhost:$rpc_port/status | jq -r '.result.sync_info.latest_block_height')
    local network_height=$(curl -s https://story-rpc-cosmos.originstake.com/status | jq -r '.result.sync_info.latest_block_height')

    if ! [[ "$local_height" =~ ^[0-9]+$ ]] || ! [[ "$network_height" =~ ^[0-9]+$ ]]; then
        echo "Error: Invalid block height data."
        return
    fi

    local blocks_left=$((network_height - local_height))
    if [ "$blocks_left" -lt 0 ]; then
        blocks_left=0
    fi

    echo -e "\033[1;33mYour Node Height:\033[1;34m $local_height\033[0m \033[1;33m| Network Height:\033[1;36m $network_height\033[0m \033[1;33m| Blocks Left:\033[1;31m $blocks_left\033[0m"
}