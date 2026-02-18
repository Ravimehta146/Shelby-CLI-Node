#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

CONFIG_FILE="$HOME/.shelby_config"

show_menu() {
    clear
    echo -e "${CYAN}========================================================${NC}"
    echo -e "              SHELBY DEVNET INSTALL MANAGER"
    echo -e "${CYAN}========================================================${NC}"
    echo -e "${YELLOW}1.${NC} Install Node.js"
    echo -e "${YELLOW}2.${NC} Install Shelby CLI"
    echo -e "${YELLOW}3.${NC} Set API Key"
    echo -e "${YELLOW}4.${NC} Check Shelby Version"
    echo -e "${YELLOW}5.${NC} Exit"
    echo -e "${CYAN}========================================================${NC}"
}

install_node() {
    if command -v node >/dev/null 2>&1; then
        echo -e "${GREEN}Node.js already installed.${NC}"
        return
    fi

    echo -e "${CYAN}Installing Node.js...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs

    if command -v node >/dev/null 2>&1; then
        echo -e "${GREEN}Node.js installed successfully.${NC}"
    else
        echo -e "${RED}Node installation failed.${NC}"
    fi
}

install_shelby() {
    if command -v shelby >/dev/null 2>&1; then
        echo -e "${GREEN}Shelby CLI already installed.${NC}"
        return
    fi

    echo -e "${CYAN}Installing Shelby CLI...${NC}"
    npm install -g shelby-cli

    if command -v shelby >/dev/null 2>&1; then
        echo -e "${GREEN}Shelby CLI installed successfully.${NC}"
    else
        echo -e "${RED}Shelby installation failed.${NC}"
    fi
}

set_api_key() {
    echo -ne "${CYAN}Enter Shelby API Key: ${NC}"
    read -s API_KEY
    echo
    echo "API_KEY=$API_KEY" > "$CONFIG_FILE"
    echo -e "${GREEN}API key saved to $CONFIG_FILE${NC}"
}

check_version() {
    if command -v shelby >/dev/null 2>&1; then
        shelby --version
    else
        echo -e "${RED}Shelby CLI not installed.${NC}"
    fi
}

while true; do
    show_menu
    read -p "Select an option: " choice

    case $choice in
        1) install_node ;;
        2) install_shelby ;;
        3) set_api_key ;;
        4) check_version ;;
        5) echo -e "${GREEN}Goodbye.${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid option.${NC}" ;;
    esac

    echo
    read -p "Press Enter to continue..."
done
