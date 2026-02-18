#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

CONFIG_FILE="$HOME/.shelby_config"

show_header() {
    clear
    echo -e "${CYAN}========================================================${NC}"
    echo -e "${BOLD}              SHELBY DEVNET INSTALL MANAGER${NC}"
    echo -e "${CYAN}========================================================${NC}"
}

install_node() {
    if command -v node >/dev/null 2>&1; then
        echo -e "${GREEN}Node.js already installed.${NC}"
        node -v
        return
    fi

    echo -e "${CYAN}Installing Node.js 20...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs

    if command -v node >/dev/null 2>&1; then
        echo -e "${GREEN}Node.js installed successfully.${NC}"
        node -v
    else
        echo -e "${RED}Node installation failed.${NC}"
    fi
}

install_shelby() {
    if command -v shelby >/dev/null 2>&1; then
        echo -e "${GREEN}Shelby CLI already installed.${NC}"
        shelby --version
        return
    fi

    echo -e "${CYAN}Installing Shelby CLI...${NC}"
    npm install -g @shelby-protocol/cli

    if command -v shelby >/dev/null 2>&1; then
        echo -e "${GREEN}Shelby CLI installed successfully.${NC}"
        shelby --version
    else
        echo -e "${RED}Shelby installation failed.${NC}"
    fi
}

initialize_shelby() {
    if ! command -v shelby >/dev/null 2>&1; then
        echo -e "${RED}Shelby CLI not installed.${NC}"
        return
    fi

    echo -e "${CYAN}Initializing Shelby CLI...${NC}"
    shelby init
}

set_api_key() {
    echo -ne "${CYAN}Enter Shelby API Key: ${NC}"
    read -s API_KEY
    echo
    echo "API_KEY=$API_KEY" > "$CONFIG_FILE"
    echo -e "${GREEN}API key saved to $CONFIG_FILE${NC}"
}

view_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        MASKED="${API_KEY:0:6}****"
        echo -e "${YELLOW}Saved API Key:${NC} $MASKED"
    else
        echo -e "${RED}No config file found.${NC}"
    fi
}

check_version() {
    if command -v shelby >/dev/null 2>&1; then
        shelby --version
    else
        echo -e "${RED}Shelby CLI not installed.${NC}"
    fi
}

while true; do
    show_header

    echo -e "${YELLOW}1.${NC} Install Node.js"
    echo -e "${YELLOW}2.${NC} Install Shelby CLI"
    echo -e "${YELLOW}3.${NC} Initialize Shelby (shelby init)"
    echo -e "${YELLOW}4.${NC} Set API Key"
    echo -e "${YELLOW}5.${NC} View Saved API Key"
    echo -e "${YELLOW}6.${NC} Check Shelby Version"
    echo -e "${YELLOW}7.${NC} Exit"
    echo -e "${CYAN}========================================================${NC}"

    read -p "Select an option: " choice

    case $choice in
        1) install_node ;;
        2) install_shelby ;;
        3) initialize_shelby ;;
        4) set_api_key ;;
        5) view_config ;;
        6) check_version ;;
        7) echo -e "${GREEN}Goodbye.${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid option.${NC}" ;;
    esac

    echo
    read -p "Press Enter to continue..."
done
