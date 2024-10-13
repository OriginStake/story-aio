#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

SCRIPT_NAME="story-script.sh"
CURRENT_VERSION="1.0.0"

# Determine OS and architecture
if [[ "$(uname)" == "Darwin" ]]; then
    export OS_TYPE="darwin"
elif [[ "$(uname)" == "Linux" ]]; then
    export OS_TYPE="linux"
else
    export OS_TYPE="unknown"
fi

if [[ "$(uname -m)" == "x86_64" ]]; then
    export ARCH="amd64"
elif [[ "$(uname -m)" == "aarch64" || "$(uname -m)" == "arm64" ]]; then
    export ARCH="arm64"
else
    export ARCH="unknown"
fi

# Define an array for main menu options
MAIN_MENU_OPTIONS=(
    "Install Story - All-in-One Script"
    "Start/Stop/Check/Remove Story Service"
    "Story Tools"
    "Secure Story Node"
    "Check ENV & Wallet Info"
    "Manage AIO Script"
    "Exit"
)
