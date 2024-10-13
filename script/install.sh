#!/bin/bash

source "$SCRIPT_DIR/script/config.sh"
source "$SCRIPT_DIR/script/utils.sh"

INSTALL_LOG="$HOME/install_log.txt"
ENV_FILE="$HOME/.story_env"

STORY_GETH_REPO="piplabs/story-geth"
STORY_REPO="piplabs/story"

STORY_GETH_VERSION="v0.9.3"
STORY_VERSION="v0.9.13"

STORY_GETH_BASE_URL="https://story-geth-binaries.s3.us-west-1.amazonaws.com/geth-public"
STORY_BASE_URL="https://story-geth-binaries.s3.us-west-1.amazonaws.com/story-public"

function check_and_install_dependencies() {
    echo "Checking and installing necessary dependencies..."
    
    if [[ "$OS_TYPE" == "linux" ]]; then
        sudo apt-get update
        sudo apt-get install -y curl jq
    elif [[ "$OS_TYPE" == "darwin" ]]; then
        brew install jq
    fi
    
    if ! command -v jq &> /dev/null; then
        echo "Unable to install jq. Please install it manually and run the script again."
        exit 1
    fi

    echo "Dependencies installed successfully."
}

check_and_install_dependencies

function log() {
    local message="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" | tee -a "$INSTALL_LOG"
}

function handle_error() {
    log "Error: $1"
    exit 1
}

function download_with_progress() {
    local url=$1
    local output=$2
    log "Downloading $(basename $output)..."
    if [[ "$OS_TYPE" == "darwin" ]]; then
        curl -L --progress-bar "$url" -o "$output"
    else
        wget --no-check-certificate --progress=bar:force:noscroll -O "$output" "$url" 2>&1 | \
        while read -r line; do
            if [[ $line =~ [0-9]+% ]]; then
                echo -ne "\rProgress: $line"
            fi
        done
    fi
    echo -e "\nDownload complete."
    
    if [ ! -s "$output" ]; then
        handle_error "Downloaded file is empty: $output"
    fi
}

function write_env() {
    local key=$1
    local value=$2
    echo "$key=$value" >> "$ENV_FILE"
}

function show_install_menu() {
    clear
    print_simple_header
    echo "Story Installation Options:"
    echo "1) Automated Installation"
    echo "2) Return to Main Menu"
    echo
    read -p "Please select an option [1-2]: " install_choice

    case $install_choice in
        1) automated_install ;;
        2) return ;;
        *) echo "Invalid option. Please try again."; sleep 2; show_install_menu ;;
    esac
}

function get_asset_url() {
    local type=$1
    local os_type=$2
    local arch=$3
    
    if [ "$type" = "geth" ]; then
        echo "${STORY_GETH_BASE_URL}/geth-${os_type}-${arch}-${STORY_GETH_VERSION#v}-b224fdf.tar.gz"
    elif [ "$type" = "story" ]; then
        echo "${STORY_BASE_URL}/story-${os_type}-${arch}-${STORY_VERSION#v}-b4c7db1.tar.gz"
    else
        echo "Error: Invalid type specified" >&2
        return 1
    fi
}

function automated_install() {
    if [[ -z "$INSTALL_DIR" ]]; then
        if [[ "$OS_TYPE" == "linux" || "$OS_TYPE" == "darwin" ]]; then
            INSTALL_DIR="/usr/local/bin"
        else
            echo "Unsupported operating system. Falling back to manual installation."
            advanced_install
            return
        fi
    fi
    
    if [ ! -d "$INSTALL_DIR" ]; then
        mkdir -p "$INSTALL_DIR" || handle_error "Failed to create installation directory"
    fi
    
    INSTALL_TYPE="automated"
    STORY_DIR="$HOME/.story"
    STORY_CONFIG_DIR="$STORY_DIR/story"
    GETH_CONFIG_DIR="$STORY_DIR/"
    GETH_PORT=30311
    STORY_PORT_PREFIX=26
    CHAIN_ID="iliad"
    WALLET="my_wallet"
    MONIKER="my_node"
    
    while true; do
        clear
        echo -e "Automated Installation Settings:"
        echo -e "1) Binary Directory: ${YELLOW}$INSTALL_DIR${NC}"
        echo -e "2) Story Directory: ${YELLOW}$STORY_DIR${NC}"
        echo -e "   Story Config: ${YELLOW}$STORY_CONFIG_DIR${NC}"
        echo -e "   Geth Config: ${YELLOW}$GETH_CONFIG_DIR${NC}"
        echo -e "3) Story-Geth Port: ${BLUE}$GETH_PORT${NC}"
        echo -e "4) Story Ports: ${BLUE}${STORY_PORT_PREFIX}656, ${STORY_PORT_PREFIX}657, ${STORY_PORT_PREFIX}658, ${STORY_PORT_PREFIX}660${NC}"
        echo "   (Enter a new prefix to change all ports, e.g., 13 for 13656, 13657, etc.)"
        echo -e "5) Chain ID: ${GREEN}$CHAIN_ID${NC}"
        echo -e "6) Story-Geth Version: ${YELLOW}$STORY_GETH_VERSION${NC}"
        echo -e "7) Story Version: ${YELLOW}$STORY_VERSION${NC}"
        echo -e "8) Wallet Name: ${GREEN}$WALLET${NC}"
        echo -e "9) Moniker: ${GREEN}$MONIKER${NC}"
        echo -e "${BOLD}10) Start Installation${NC}"
        echo -e "${BOLD}11) Return to Main Menu${NC}"
        echo
        read -p "Enter the number of the setting you want to change (or 10 to start installation): " choice

        case $choice in
            1) read -p "Enter new Binary Directory: " INSTALL_DIR ;;
            2) read -p "Enter new Story Directory: " STORY_DIR 
               STORY_CONFIG_DIR="$STORY_DIR/story"
               GETH_CONFIG_DIR="$STORY_DIR/" ;;
            3) read -p "Enter new Story-Geth Port: " GETH_PORT ;;
            4) 
                read -p "Enter new Story Port prefix (current: $STORY_PORT_PREFIX): " new_prefix
                if [[ $new_prefix =~ ^[0-9]{2}$ ]]; then
                    STORY_PORT_PREFIX=$new_prefix
                    echo "Story Ports will be changed to: ${STORY_PORT_PREFIX}656, ${STORY_PORT_PREFIX}657, ${STORY_PORT_PREFIX}658, ${STORY_PORT_PREFIX}660"
                else
                    echo "Invalid input. Please enter a two-digit number."
                fi
                sleep 2
                ;;
            5) read -p "Enter new Chain ID: " CHAIN_ID ;;
            6) read -p "Enter new Story-Geth Version: " STORY_GETH_VERSION ;;
            7) read -p "Enter new Story Version: " STORY_VERSION ;;
            8) read -p "Enter new Wallet Name: " WALLET ;;
            9) read -p "Enter new Moniker: " MONIKER ;;
            10) 
                echo "Starting installation..."
                sleep 2
                break 
                ;;
            11) return ;;
            *) echo "Invalid option. Please try again." ;;
        esac
    done
    
    install_story
}

function advanced_install() {
    source ./custom_install.sh
    if advanced_install; then
        INSTALL_TYPE="custom"
        install_story
    else
        echo "Custom installation cancelled."
        return
    fi
}

function install_story() {
    log "Starting Story installation process..."

    if [ ! -d "$INSTALL_DIR" ]; then
        mkdir -p "$INSTALL_DIR" || handle_error "Failed to create installation directory"
    fi
    
    log "Installation directory: $INSTALL_DIR"

    TMP_DIR=$(mktemp -d)
    log "Created temporary directory: $TMP_DIR"

    log "Downloading and installing Story-Geth binary..."
    STORY_GETH_URL=$(get_asset_url "geth" "$OS_TYPE" "$ARCH")
    log "Attempting to download from: $STORY_GETH_URL"
    GETH_FILENAME=$(basename "$STORY_GETH_URL")
    download_with_progress "$STORY_GETH_URL" "$TMP_DIR/$GETH_FILENAME" || handle_error "Failed to download Story-Geth"

    if [ ! -s "$TMP_DIR/$GETH_FILENAME" ]; then
        handle_error "Downloaded Story-Geth file is empty. URL might be incorrect: $STORY_GETH_URL"
    fi

    tar -xzvf "$TMP_DIR/$GETH_FILENAME" -C "$TMP_DIR" || handle_error "Failed to extract Story-Geth"
    find "$TMP_DIR" -name "geth" -type f -exec cp {} "$INSTALL_DIR/story-geth" \; || handle_error "Failed to copy Story-Geth binary"
    chmod +x "$INSTALL_DIR/story-geth" || handle_error "Failed to set permissions for Story-Geth"
    log "Story-Geth binary installed at $INSTALL_DIR/story-geth"

    log "Downloading and installing Story binary..."
    STORY_URL=$(get_asset_url "story" "$OS_TYPE" "$ARCH")
    log "Attempting to download from: $STORY_URL"
    STORY_FILENAME=$(basename "$STORY_URL")
    download_with_progress "$STORY_URL" "$TMP_DIR/$STORY_FILENAME" || handle_error "Failed to download Story"

    if [ ! -s "$TMP_DIR/$STORY_FILENAME" ]; then
        handle_error "Downloaded Story file is empty. URL might be incorrect: $STORY_URL"
    fi

    tar -xzvf "$TMP_DIR/$STORY_FILENAME" -C "$TMP_DIR" || handle_error "Failed to extract Story"
    find "$TMP_DIR" -name "story" -type f -exec cp {} "$INSTALL_DIR/story" \; || handle_error "Failed to copy Story binary"
    chmod +x "$INSTALL_DIR/story" || handle_error "Failed to set permissions for Story"
    log "Story binary installed at $INSTALL_DIR/story"

    BACKUP_DIR="$HOME/story_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p $BACKUP_DIR
    if [ -d "$STORY_DIR" ]; then
        cp -r "$STORY_DIR" $BACKUP_DIR/
        log "Existing configuration backed up to $BACKUP_DIR"
    fi

    log "Initializing $CHAIN_ID network node..."
    $INSTALL_DIR/story init --moniker "$MONIKER" --network "$CHAIN_ID" --home "$STORY_CONFIG_DIR" || handle_error "Failed to initialize $CHAIN_ID network node"

    configure_story

    if [[ "$OS_TYPE" == "linux" ]]; then
        create_systemd_services

        log "Reloading systemd, enabling and starting Story-Geth and Story services..."
        systemctl daemon-reload || handle_error "Failed to reload systemd"
        systemctl enable story-geth story || handle_error "Failed to enable services"

        log "Verifying installation..."
        if systemctl is-enabled --quiet story-geth && systemctl is-enabled --quiet story; then
            log "Story-Geth and Story services are enabled."
            log "You can start the services using 'systemctl start story-geth story'."
        else
            handle_error "Services are not enabled. Please check the logs."
        fi
    elif [[ "$OS_TYPE" == "darwin" ]]; then
        log "On macOS, you need to start the services manually or create launchd jobs."
        log "To start Story-Geth: $INSTALL_DIR/story-geth --$CHAIN_ID --syncmode full --home $STORY_DIR --port $GETH_PORT"
        log "To start Story: $INSTALL_DIR/story run --home $STORY_DIR"
    fi

    log "Verifying installed versions..."
    INSTALLED_GETH_VERSION=$("$INSTALL_DIR/story-geth" version 2>&1 | grep "Version:" | awk '{print $2}')
    INSTALLED_STORY_VERSION=$("$INSTALL_DIR/story" version 2>&1 | grep "Version:" | awk '{print $2}')

    if [ -z "$INSTALLED_GETH_VERSION" ]; then
        log "Warning: Unable to verify Story-Geth version. Output: $("$INSTALL_DIR/story-geth" version 2>&1)"
    else
        log "Installed Story-Geth version: $INSTALLED_GETH_VERSION"
    fi

    if [ -z "$INSTALLED_STORY_VERSION" ]; then
        log "Warning: Unable to verify Story version. Output: $("$INSTALL_DIR/story" version 2>&1)"
    else
        log "Installed Story version: $INSTALLED_STORY_VERSION"
    fi

    if [ -z "$INSTALLED_GETH_VERSION" ] || [ -z "$INSTALLED_STORY_VERSION" ]; then
        log "Warning: Unable to verify one or both installed versions. Please check manually."
    else
        log "Successfully verified both Story-Geth and Story versions."
    fi

    log "Cleaning up temporary files..."
    rm -rf "$TMP_DIR"

    log "Story installation complete!"
    log "Backup of previous configuration (if any) is stored in $BACKUP_DIR"

    echo "# Story Installation Environment Variables" > "$ENV_FILE"
    write_env "STORY_GETH_VERSION" "$STORY_GETH_VERSION"
    write_env "STORY_VERSION" "$STORY_VERSION"
    write_env "INSTALL_DIR" "$INSTALL_DIR"
    write_env "STORY_DIR" "$STORY_DIR"
    write_env "STORY_GETH_BINARY" "$INSTALL_DIR/story-geth"
    write_env "STORY_BINARY" "$INSTALL_DIR/story"
    write_env "BACKUP_DIR" "$BACKUP_DIR"
    write_env "INSTALL_LOG" "$INSTALL_LOG"
    write_env "OS_TYPE" "$OS_TYPE"
    write_env "GETH_PORT" "$GETH_PORT"
    write_env "STORY_PORT_PREFIX" "$STORY_PORT_PREFIX"
    write_env "CHAIN_ID" "$CHAIN_ID"
    write_env "WALLET" "$WALLET"
    write_env "MONIKER" "$MONIKER"
    write_env "INSTALL_DATE" "$(date '+%Y-%m-%d %H:%M:%S')"

    log "Environment variables written to $ENV_FILE"

    SUMMARY=$(cat <<EOF

${BOLD}Installation Summary:${NC}
---------------------
Story-Geth Version: ${YELLOW}$STORY_GETH_VERSION${NC}
Story Version: ${YELLOW}$STORY_VERSION${NC}
Installation Directory: ${YELLOW}$INSTALL_DIR${NC}
Story Directory: ${YELLOW}$STORY_DIR${NC}
Story-Geth Binary: ${YELLOW}$INSTALL_DIR/story-geth${NC}
Story Binary: ${YELLOW}$INSTALL_DIR/story${NC}
Backup Directory: ${BLUE}$BACKUP_DIR${NC}
Log File: ${BLUE}$INSTALL_LOG${NC}
ENV File: ${BLUE}$ENV_FILE${NC}
Story-Geth Port: ${BLUE}$GETH_PORT${NC}
Story Ports: ${BLUE}${STORY_PORT_PREFIX}656, ${STORY_PORT_PREFIX}657, ${STORY_PORT_PREFIX}658, ${STORY_PORT_PREFIX}660${NC}
Chain ID: ${GREEN}$CHAIN_ID${NC}
Moniker: ${GREEN}$MONIKER${NC}

EOF
)

    echo "$SUMMARY" | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" >> "$INSTALL_LOG"

    echo -e "$SUMMARY"
    echo -e "For more details, please check the log file: ${BLUE}$INSTALL_LOG${NC}"
    echo -e "Environment variables are stored in: ${BLUE}$ENV_FILE${NC}"
    echo
    
    echo "Installation completed successfully. Press Enter to proceed to the service management menu..."
    read

    # Gọi menu service
    source "$SCRIPT_DIR/script/service.sh"
    story_service_menu

    # Cập nhật vị trí thực tế của binary trong file môi trường
    actual_story_geth_binary=$(which story-geth)
    actual_story_binary=$(which story)
    sed -i "s|^STORY_GETH_BINARY=.*|STORY_GETH_BINARY=$actual_story_geth_binary|" "$ENV_FILE"
    sed -i "s|^STORY_BINARY=.*|STORY_BINARY=$actual_story_binary|" "$ENV_FILE"
}

function configure_story() {
    log "Configuring Story..."

    SEEDS="51ff395354c13fab493a03268249a74860b5f9cc@story-testnet-seed.itrocket.net:26656,3f472746f46493309650e5a033076689996c8881@story-testnet.rpc.kjnodes.com:26659,3f472746f46493309650e5a033076689996c8881@story-testnet.rpc.kjnodes.com:26659"
    sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" $STORY_CONFIG_DIR/config/config.toml

    log "Fetching peers from RPC..."
    URL="https://story-rpc-cosmos.originstake.com/net_info"
    response=$(curl -s $URL)
    if [ $? -ne 0 ]; then
        log "Unable to connect to RPC endpoint. Using default peers."
        PEERS="2f372238bf86835e8ad68c0db12351833c40e8ad@story-testnet-peer.itrocket.net:26656,343507f6105c8ebced67765e6d5bf54bc2117371@38.242.234.33:26656"
    else
        PEERS=$(echo $response | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):" + (.node_info.listen_addr | capture("(?<ip>.+):(?<port>[0-9]+)$").port)' | paste -sd "," -)
        if [ -z "$PEERS" ]; then
            log "No peers found. Using default peers."
            PEERS="2f372238bf86835e8ad68c0db12351833c40e8ad@story-testnet-peer.itrocket.net:26656,343507f6105c8ebced67765e6d5bf54bc2117371@38.242.234.33:26656"
        else
            log "Successfully fetched peers from RPC."
        fi
    fi

    sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" $STORY_CONFIG_DIR/config/config.toml

    wget -O $STORY_CONFIG_DIR/config/genesis.json https://raw.githubusercontent.com/OriginStake/story-aio/refs/heads/main/genesis-assets/genesis.json

    wget -O $STORY_CONFIG_DIR/config/addrbook.json https://raw.githubusercontent.com/OriginStake/story-aio/refs/heads/main/genesis-assets/addrbook.json


    # Update both port and JWT path
    sed -i.bak -e "s%:1317%:${STORY_PORT_PREFIX}317%g;
    s%/root/.story/geth/iliad/geth/jwtsecret%$STORY_DIR/geth/$CHAIN_ID/geth/jwtsecret%g" $STORY_CONFIG_DIR/config/story.toml
    sed -i.bak -e "s%:26658%:${STORY_PORT_PREFIX}658%g;
    s%:26657%:${STORY_PORT_PREFIX}657%g;
    s%:26656%:${STORY_PORT_PREFIX}656%g;
    s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${STORY_PORT_PREFIX}656\"%;
    s%:26660%:${STORY_PORT_PREFIX}660%g" $STORY_CONFIG_DIR/config/config.toml

    sed -i -e "s/prometheus = false/prometheus = true/" $STORY_CONFIG_DIR/config/config.toml
    sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $STORY_CONFIG_DIR/config/config.toml

    log "Story configuration complete."
}

function create_systemd_services() {
    log "Creating systemd services..."

    cat > /etc/systemd/system/story-geth.service <<EOF
[Unit]
Description=Story Geth Client
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$STORY_DIR
ExecStart=$INSTALL_DIR/story-geth \\
    --$CHAIN_ID \\
    --syncmode full \\
    --http \\
    --http.api eth,net,web3,engine \\
    --http.vhosts '*' \\
    --http.addr 0.0.0.0 \\
    --http.port $GETH_PORT \\
    --ws \\
    --ws.api eth,web3,net,txpool \\
    --ws.addr 0.0.0.0 \\
    --ws.port $(($GETH_PORT+1)) \\
    --bootnodes enode://08e4b916327f2b9ef47d6b76fb77619eacb045c1054e2cb1e3abcc4c355907e3791a2f6f873cacfe2d99671f53299c575663d647e6bc855bf9d2c73751d1208e@b1.testnet.storyrpc.io:30303,enode://3bae9a46ddf39b805f678dd8ba8624c28285417d4bdbf5212234ee83a4cf94335bfd32b449a37bcf39b609208f8556ce42d6ee60c657f2a75b893350c1bd347f@b2.testnet.storyrpc.io:30303 \\
    --authrpc.jwtsecret $STORY_DIR/geth/$CHAIN_ID/geth/jwtsecret
Restart=always
RestartSec=3
LimitNOFILE=infinity
Nice=-10

[Install]
WantedBy=multi-user.target
EOF

    cat > /etc/systemd/system/story.service <<EOF
[Unit]
Description=Story Consensus Client
After=network.target

[Service]
User=$USER
ExecStart=$INSTALL_DIR/story run --home $STORY_CONFIG_DIR
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

    log "Systemd services created."
}

function main() {
    show_install_menu
}

main "$@"