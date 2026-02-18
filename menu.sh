#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

UPLOAD_DIR="$HOME/shelby_uploads"
LOG_DIR="$HOME/shelby_logs"
mkdir -p "$UPLOAD_DIR"
mkdir -p "$LOG_DIR"

show_menu() {
    clear
    echo -e "${CYAN}====================================================${NC}"
    echo "               Shelby Devnet Manager"
    echo -e "${CYAN}====================================================${NC}"
    echo -e "${YELLOW}1.${NC} Install Node.js"
    echo -e "${YELLOW}2.${NC} Install Shelby CLI"
    echo -e "${YELLOW}3.${NC} Initialize Shelby"
    echo -e "${YELLOW}4.${NC} Faucet (Get Tokens)"
    echo -e "${YELLOW}5.${NC} Check Balance"
    echo -e "${YELLOW}6.${NC} List My Blobs"
    echo -e "${YELLOW}7.${NC} Auto Download & Upload Image (Pixabay)"
    echo -e "${YELLOW}8.${NC} Auto Download & Upload Video (Pixabay)"
    echo -e "${YELLOW}9.${NC} Auto Upload From Folder"
    echo -e "${YELLOW}10.${NC} Blob Manager (Download / Delete / Search)"
    echo -e "${YELLOW}11.${NC} Export Address + Private Key"
    echo -e "${YELLOW}0.${NC} Exit"
    echo -e "${CYAN}====================================================${NC}"
}

install_node() {
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt install -y nodejs
    node -v
}

install_shelby() {
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

list_blobs() {
    shelby account blobs
}

# ================= IMAGE UPLOAD =================

upload_random_image() {

    API_KEY=$(cat "$HOME/.pixabay_api_key" 2>/dev/null)
    if [ -z "$API_KEY" ]; then
        echo -e "${RED}Pixabay API key not found.${NC}"
        return
    fi

    PAGE=$(( RANDOM % 20 + 1 ))
    RESPONSE=$(curl -s "https://pixabay.com/api/?key=$API_KEY&page=$PAGE&per_page=50")

    TOTAL=$(echo "$RESPONSE" | jq '.hits | length')
    [ "$TOTAL" -eq 0 ] && echo "No images found." && return

    INDEX=$(( RANDOM % TOTAL ))
    URL=$(echo "$RESPONSE" | jq -r ".hits[$INDEX].largeImageURL")

    TIMESTAMP="$(date +%s)-$RANDOM"
    FILE="$PWD/image-$TIMESTAMP.jpg"
    BLOB="image-$TIMESTAMP.jpg"

    curl -L -o "$FILE" "$URL"

    shelby upload "$FILE" "$BLOB" -e "in 7 days" --assume-yes

    rm -f "$FILE"
}

# ================= VIDEO UPLOAD =================

upload_random_video() {

    API_KEY=$(cat "$HOME/.pixabay_api_key" 2>/dev/null)
    if [ -z "$API_KEY" ]; then
        echo -e "${RED}Pixabay API key not found.${NC}"
        return
    fi

    PAGE=$(( RANDOM % 20 + 1 ))
    RESPONSE=$(curl -s "https://pixabay.com/api/videos/?key=$API_KEY&page=$PAGE&per_page=20")

    TOTAL=$(echo "$RESPONSE" | jq '.hits | length')
    [ "$TOTAL" -eq 0 ] && echo "No videos found." && return

    INDEX=$(( RANDOM % TOTAL ))
    URL=$(echo "$RESPONSE" | jq -r ".hits[$INDEX].videos.small.url")

    TIMESTAMP="$(date +%s)-$RANDOM"
    FILE="$PWD/video-$TIMESTAMP.mp4"
    BLOB="video-$TIMESTAMP.mp4"

    curl -L -o "$FILE" "$URL"

    shelby upload "$FILE" "$BLOB" -e "in 7 days" --assume-yes

    rm -f "$FILE"
}

# ================= AUTO FOLDER UPLOAD =================

auto_upload_from_folder() {

    FILES=("$UPLOAD_DIR"/*)
    [ ${#FILES[@]} -eq 0 ] && echo "No files in $UPLOAD_DIR" && return

    INDEX=$(( RANDOM % ${#FILES[@]} ))
    FILE="${FILES[$INDEX]}"
    BLOB=$(basename "$FILE")

    shelby upload "$FILE" "$BLOB" -e "in 7 days" --assume-yes
}

# ================= DOWNLOAD =================

blob_manager() {

    DOWNLOAD_DIR="$HOME/shelby_downloads"
    mkdir -p "$DOWNLOAD_DIR"

    echo -e "${CYAN}Fetching blobs...${NC}"
    RAW=$(shelby account blobs 2>/dev/null)
    
    # Remove ANSI color codes
RAW=$(echo "$RAW" | sed 's/\x1b\[[0-9;]*m//g')

    if [ -z "$RAW" ]; then
        echo -e "${RED}No blobs found.${NC}"
        return
    fi

    # Extract only rows that contain actual file entries
    mapfile -t LINES < <(
        echo "$RAW" |
        awk '/Stored Blobs/{flag=1; next} /Done!/{flag=0} flag' |
        grep '\.jpg\|\.mp4\|\.png\|\.pdf\|\.txt'
    )

    if [ ${#LINES[@]} -eq 0 ]; then
        echo -e "${RED}No blobs available.${NC}"
        return
    fi

    echo
    read -p "Search keyword (press Enter to skip): " FILTER

    echo
    i=1
    declare -a NAMES
    declare -a SIZES

    for line in "${LINES[@]}"; do

        # Extract name and size using column split
        NAME=$(echo "$line" | awk -F '│' '{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        SIZE=$(echo "$line" | awk -F '│' '{print $3}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        # Apply search filter
        if [ -n "$FILTER" ]; then
            echo "$NAME" | grep -iq "$FILTER" || continue
        fi

        if [ -n "$NAME" ]; then
            NAMES[$i]="$NAME"
            SIZES[$i]="$SIZE"
            echo "$i) $NAME  |  Size: $SIZE"
            ((i++))
        fi

    done

    if [ $i -eq 1 ]; then
        echo -e "${RED}No matching blobs found.${NC}"
        return
    fi

    echo
    read -p "Select file number: " CHOICE

    SELECTED="${NAMES[$CHOICE]}"
    SIZE_SELECTED="${SIZES[$CHOICE]}"

    if [ -z "$SELECTED" ]; then
        echo -e "${RED}Invalid selection.${NC}"
        return
    fi

    echo
    echo "Selected: $SELECTED"
    echo "Size: $SIZE_SELECTED"
    echo
    echo "1) Download"
    echo "2) Cancel"
    read -p "Choose action: " ACTION

    case $ACTION in
    1)
        OUT="$DOWNLOAD_DIR/$SELECTED"

        printf 'DEBUG HEX: '
        printf '%s' "$SELECTED" | hexdump -C
        echo

        if shelby download "$SELECTED" "$OUT"; then
            echo -e "${GREEN}Saved to $OUT${NC}"
        else
            echo -e "${RED}Download failed.${NC}"
        fi
        ;;
        *)
            echo "Cancelled."
            ;;
    esac
}

# ================= EXPORT ACCOUNT =================

export_account() {

    CONFIG="$HOME/.shelby/config.yaml"

    if [ ! -f "$CONFIG" ]; then
        echo "Shelby not initialized."
        return
    fi

    echo -e "${RED}WARNING: This will display your private key.${NC}"
    read -p "Type YES to continue: " CONFIRM

    [ "$CONFIRM" != "YES" ] && echo "Cancelled." && return

    echo
    echo "Address:"
    shelby account list
    echo
    echo "Private Key:"
    grep -i "private" "$CONFIG"
}

# ================= MAIN LOOP =================

while true; do
    show_menu
    read -p "Select option: " OPT

    case $OPT in
        1) install_node ;;
        2) install_shelby ;;
        3) initialize_shelby ;;
        4) faucet ;;
        5) check_balance ;;
        6) list_blobs ;;
        7) upload_random_image ;;
        8) upload_random_video ;;
        9) auto_upload_from_folder ;;
        10) blob_manager ;;
        11) export_account ;;
        0) exit 0 ;;
        *) echo "Invalid option." ;;
    esac

    echo
    read -p "Press Enter to continue..."
done
