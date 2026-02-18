#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

show_menu() {
    clear
    echo -e "${CYAN}================================================${NC}"
    echo "           Shelby Devnet CLI Full Guide"
    echo -e "${CYAN}================================================${NC}"
    echo -e "${YELLOW}1.${NC} Install Dependencies"
    echo -e "${YELLOW}2.${NC} Install Node.js & Git"
    echo -e "${YELLOW}3.${NC} Install Shelby CLI"
    echo -e "${YELLOW}4.${NC} Initialize Shelby CLI"
    echo -e "${YELLOW}5.${NC} Faucet (Get free APT + ShelbyUSD)"
    echo -e "${YELLOW}6.${NC} Check Account Balance"
    echo -e "${YELLOW}7.${NC} Upload a File"
    echo -e "${YELLOW}8.${NC} Download a File"
    echo -e "${YELLOW}9.${NC} Daily Upload Helper"
    echo -e "${YELLOW}0.${NC} Exit"
    echo -e "${CYAN}================================================${NC}"
}

install_deps() {
    echo -e "${CYAN}Installing required dependencies...${NC}"
    sudo apt-get update && sudo apt-get upgrade -y
    sudo apt install curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev -y
    sudo apt install -y libssl-dev ca-certificates
    echo -e "${GREEN}Dependencies installed.${NC}"
}

install_node_git() {
    echo -e "${CYAN}Installing Node.js & Git...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt install -y nodejs git
    echo -e "${GREEN}Node.js, npm, and Git versions:${NC}"
    node -v
    npm -v
    git --version
}

install_shelby_cli() {
    echo -e "${CYAN}Installing Shelby CLI...${NC}"
    npm i -g @shelby-protocol/cli
    echo -e "${GREEN}Shelby CLI version:${NC}"
    shelby --version
}

initialize_shelby() {
    echo -e "${CYAN}Initializing Shelby CLI...${NC}"
    shelby init
}

faucet() {
    echo -e "${CYAN}Running faucet command...${NC}"
    shelby faucet --no-open
    echo -e "${YELLOW}Copy the URL above and open it in a browser to fund APT & ShelbyUSD tokens.${NC}"
}

check_balance() {
    echo -e "${CYAN}Fetching account balance...${NC}"
    shelby account balance
}

upload_file() {
    echo -e "${CYAN}Upload path and blob name:[enter]${NC}"
    read -p "Local file: " localpath
    read -p "Shelby blob name: " blobname
    shelby upload "$localpath" "$blobname" -e "in 7 days" --assume-yes
}

download_file() {
    echo -e "${CYAN}Download blob to file:[enter]${NC}"
    read -p "Blob name: " blob
    read -p "Save as: " outfile
    shelby download "$blob" "$outfile"
}

daily_upload() {
    echo -e "${CYAN}Daily upload helper${NC}"
    read -p "Enter a message for the file: " msg
    FILE="daily-$(date +%F-%H-%M-%S).txt"
    echo "$msg" > "$FILE"
    shelby upload "$FILE" "$FILE" -e "in 7 days" --assume-yes
    echo -e "${GREEN}Uploaded daily file as $FILE${NC}"
}

while true; do
    show_menu
    read -p "Choose an option: " opt
    case $opt in
        1) install_deps ;;
        2) install_node_git ;;
        3) install_shelby_cli ;;
        4) initialize_shelby ;;
        5) faucet ;;
        6) check_balance ;;
        7) upload_file ;;
        8) download_file ;;
        9) daily_upload ;;
        0) echo -e "${GREEN}Goodbye!${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid choice${NC}" ;;
    esac
    echo
    read -p "Press Enter to continue..."
done
