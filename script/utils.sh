#!/bin/bash

source "$SCRIPT_DIR/script/config.sh"

function print_ascii_art() {
    echo -e "\033[0;34m"
    echo " ███████╗████████╗ ██████╗ ██████╗ ██╗   ██╗"
    echo " ██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗╚██╗ ██╔╝"
    echo " ███████╗   ██║   ██║   ██║██████╔╝ ╚████╔╝ "
    echo " ╚════██║   ██║   ██║   ██║██╔══██╗  ╚██╔╝  "
    echo " ███████║   ██║   ╚██████╔╝██║  ██║   ██║   "
    echo " ╚══════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝   ╚═╝   "
    echo "                                            "
    echo " ██████╗ ██████╗  ██████╗ ████████╗ ██████╗  ██████╗ ██████╗ ██╗     "
    echo " ██╔══██╗██╔══██╗██╔═══██╗╚══██╔══╝██╔═══██╗██╔════╝██╔═══██╗██║     "
    echo " ██████╔╝██████╔╝██║   ██║   ██║   ██║   ██║██║     ██║   ██║██║     "
    echo " ██╔═══╝ ██╔══██╗██║   ██║   ██║   ██║   ██║██║     ██║   ██║██║     "
    echo " ██║     ██║  ██║╚██████╔╝   ██║   ╚██████╔╝╚██████╗╚██████╔╝███████╗"
    echo " ╚═╝     ╚═╝  ╚═╝ ╚═════╝    ╚═╝    ╚═════╝  ╚═════╝ ╚═════╝ ╚══════╝"
    echo -e "\033[0m"
}

function print_simple_header {
    echo -e "Story Install Script (v1.0.0)\033[0m - \033[1m\033[1;33mFrom OriginStake.com with \033[0;31m<3\033[0m"
    echo -e "\n"
}

function print_settings {
    echo -e "\033[1mYour current settings:\033[0m"
    
    local story_info=""
    local geth_info=""
    local column_width=40
    
    if command -v story &> /dev/null; then
        story_output=$(story version 2>&1)
        story_version=$(echo "$story_output" | awk '/Version/{print $2; exit}')
        story_commit=$(echo "$story_output" | awk '/Git Commit/{print $3; exit}')
        story_timestamp=$(echo "$story_output" | awk '/Git Timestamp/{print $3, $4; exit}')
        story_info+="Story\n"
        story_info+="Version:        \033[0;32m$story_version\033[0m\n"
        story_info+="Git Commit:     \033[0;32m$story_commit\033[0m\n"
        story_info+="Git Timestamp:  \033[0;32m$story_timestamp\033[0m"
    else
        story_info+="\033[1mStory:\033[0m \033[0;31mNot installed\033[0m"
    fi

    if command -v story-geth &> /dev/null; then
        geth_output=$(story-geth version 2>&1)
        geth_version=$(echo "$geth_output" | awk '/Version:/{print $2; exit}')
        geth_commit=$(echo "$geth_output" | awk '/Git Commit:/{print $3; exit}')
        geth_commit_date=$(echo "$geth_output" | awk '/Git Commit Date:/{print $4; exit}')
        geth_info+="GETH                                    \n"
        geth_info+="Version:        \033[0;32m$geth_version\033[0m\n"
        geth_info+="Git Commit:     \033[0;32m$geth_commit\033[0m\n"
        geth_info+="Git Commit Date: \033[0;32m$geth_commit_date\033[0m"
    else
        geth_info+="\033[1mGETH:\033[0m \033[0;31mNot installed\033[0m"
    fi
    
    paste <(echo -e "$story_info") <(echo -e "$geth_info") | column -t -s $'\t'
    
    echo -e "\n\033[1mSystem Information:\033[0m"
    echo -e "OS Type:        \033[0;32m$OS_TYPE\033[0m"
    echo -e "Architecture:   \033[0;32m$ARCH\033[0m"
    
    echo -e "\n"
}
