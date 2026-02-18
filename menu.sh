#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

LOG_DIR="$HOME/shelby_logs"
mkdir -p "$LOG_DIR"

KEYWORDS=("nature" "city" "technology" "ocean" "mountains" "coding" "sunset" "forest" "space" "architecture")

show_menu() {
    clear
    echo -e "${CYAN}====================================================${NC}"
    echo "              Shelby Devnet CLI Manager"
    echo -e "${CYAN}====================================================${NC}"
    echo -e "${YELLOW}1.${NC} Install Dependencies"
    echo -e "${YELLOW}2.${NC} Install Node.js & Git"
    echo -e "${YELLOW}3.${NC} Install Shelby CLI"
    echo -e "${YELLOW}4.${NC} Initialize Shelby CLI"
    echo -e "${YELLOW}5.${NC} Faucet (Get Tokens)"
    echo -e "${YELLOW}6.${NC} Check Account Balance"
    echo -e "${YELLOW}7.${NC} Random Image Upload (Pixabay)"
    echo -e "${YELLOW}0.${NC} Exit"
    echo -e "${CYAN}====================================================${NC}"
}

install_deps() {
    sudo apt-get update && sudo apt-get upgrade -y
    sudo apt install curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip jq -y
}

install_node_git() {
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt install -y nodejs git
    node -v
    npm -v
    git --version
}

install_shelby_cli() {
    npm i -g @shelby-protocol/cli
    shelby --version
}

initialize_shelby() {
    shelby init
}

faucet() {
    shelby faucet --no-open
}

check_balance() {
    shelby account balance
}

upload_random_image() {

    if [ ! -f "$HOME/.pixabay_api_key" ]; then
        echo -e "${RED}Pixabay API key not found.${NC}"
        echo "Save it using:"
        echo "echo YOUR_API_KEY > ~/.pixabay_api_key"
        return
    fi

    API_KEY=$(cat "$HOME/.pixabay_api_key")

    RANDOM_INDEX=$(( RANDOM % ${#KEYWORDS[@]} ))
    QUERY=${KEYWORDS[$RANDOM_INDEX]}

    echo -e "${CYAN}Searching Pixabay for: $QUERY${NC}"

    RESPONSE=$(curl -s "https://pixabay.com/api/?key=$API_KEY&q=$QUERY&image_type=photo&per_page=20")

    TOTAL=$(echo "$RESPONSE" | jq '.hits | length')

    if [ "$TOTAL" -eq 0 ]; then
        echo -e "${RED}No images found.${NC}"
        return
    fi

    RANDOM_IMAGE=$(( RANDOM % TOTAL ))

    IMAGE_URL=$(echo "$RESPONSE" | jq -r ".hits[$RANDOM_IMAGE].largeImageURL")

    TIMESTAMP=$(date +%F-%H-%M-%S)
    FILENAME="$QUERY-$TIMESTAMP.jpg"

    curl -s -o "$FILENAME" "$IMAGE_URL"

    if [ ! -f "$FILENAME" ]; then
        echo -e "${RED}Image download failed.${NC}"
        return
    fi

    echo -e "${GREEN}Downloaded: $FILENAME${NC}"

    LOG_FILE="$LOG_DIR/upload-$TIMESTAMP.log"

    echo "Uploading $FILENAME" >> "$LOG_FILE"

    ATTEMPTS=0
    MAX_RETRY=3

    while [ $ATTEMPTS -lt $MAX_RETRY ]; do
        shelby upload "$FILENAME" "$FILENAME" -e "in 7 days" --assume-yes >> "$LOG_FILE" 2>&1

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Upload successful.${NC}"
            break
        else
            echo -e "${YELLOW}Upload failed. Retrying...${NC}"
            ATTEMPTS=$((ATTEMPTS + 1))
            sleep 5
        fi
    done

    if [ $ATTEMPTS -eq $MAX_RETRY ]; then
        echo -e "${RED}Upload failed after 3 attempts.${NC}"
    fi

    rm -f "$FILENAME"
    echo -e "${GREEN}Local file removed.${NC}"
}

while true; do
    show_menu
    read -p "Select option: " opt

    case $opt in
        1) install_deps ;;
        2) install_node_git ;;
        3) install_shelby_cli ;;
        4) initialize_shelby ;;
        5) faucet ;;
        6) check_balance ;;
        7) upload_random_image ;;
        0) exit 0 ;;
        *) echo -e "${RED}Invalid option.${NC}" ;;
    esac

    echo
    read -p "Press Enter to continue..."
done
