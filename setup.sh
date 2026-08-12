#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}"
cat << "EOF"
 _____ _     _____   ____        _     ____       _               
|_   _| |   | ____| | __ )  ___ | |_  / ___|  ___| |_ _   _ _ __  
  | | | |   |  _|   |  _ \ / _ \| __| \___ \ / _ \ __| | | | '_ \ 
  | | | |___| |___  | |_) | (_) | |_   ___) |  __/ |_| |_| | |_) |
  |_| |_____|_____| |____/ \___/ \__| |____/ \___|\__|\__,_| .__/ 
                                                           |_|    
EOF
echo -e "${NC}"
echo -e "${GREEN}Welcome to the interactive TLE Bot setup wizard!${NC}\n"

# Dry-run validation check
if [[ "$1" == "--check" ]]; then
    echo -e "${YELLOW}[DRY RUN MODE] Checking requirements...${NC}"
    echo -e "${GREEN}Bash version: ${BASH_VERSION}${NC}"
    exit 0
fi

# Step 1: Discord Bot Token
while true; do
    echo -e "${CYAN}Step 1: Enter your Discord Bot Token${NC}"
    echo -e "${YELLOW}Get it here: https://discord.com/developers/applications${NC}"
    echo -e "${YELLOW}(Remember to enable Server Members Intent and Message Content Intent on the Bot page!)${NC}"
    read -p "Token: " BOT_TOKEN
    
    # Very basic token validation (usually has dots, ~50-80 chars)
    if [[ "$BOT_TOKEN" == *"."* && ${#BOT_TOKEN} -ge 50 ]]; then
        echo -e "${GREEN}Token looks valid.${NC}\n"
        break
    else
        echo -e "${RED}Invalid token format. It should contain dots and be roughly 50-80 characters long.${NC}"
        echo -e "Press Ctrl+C to exit if you don't have it yet.\n"
    fi
done

# Step 2: Logging Channel ID
while true; do
    echo -e "${CYAN}Step 2: Enter Logging Channel ID (for error logs)${NC}"
    echo -e "${YELLOW}Enable Developer Mode in Discord settings, right click a channel -> Copy Channel ID${NC}"
    read -p "Channel ID: " LOGGING_CHANNEL_ID
    
    if [[ "$LOGGING_CHANNEL_ID" =~ ^[0-9]{17,20}$ ]]; then
        echo -e "${GREEN}Channel ID looks valid.${NC}\n"
        break
    else
        echo -e "${RED}Invalid Channel ID. It must be a 17-20 digit number.${NC}\n"
    fi
done

# Step 3: Admin role name
echo -e "${CYAN}Step 3: Enter Admin role name (Optional)${NC}"
read -p "Admin role [Default: Admin]: " ADMIN_ROLE
ADMIN_ROLE=${ADMIN_ROLE:-Admin}
echo -e "${GREEN}Admin role set to: $ADMIN_ROLE${NC}\n"

# Step 4: Moderator role name
echo -e "${CYAN}Step 4: Enter Moderator role name (Optional)${NC}"
read -p "Moderator role [Default: Moderator]: " MODERATOR_ROLE
MODERATOR_ROLE=${MODERATOR_ROLE:-Moderator}
echo -e "${GREEN}Moderator role set to: $MODERATOR_ROLE${NC}\n"

# Step 5: Bot prefix
echo -e "${CYAN}Step 5: Enter Bot Prefix (Optional)${NC}"
read -p "Prefix [Default: ;]: " BOT_PREFIX
BOT_PREFIX=${BOT_PREFIX:-;}
echo -e "${GREEN}Prefix set to: $BOT_PREFIX${NC}\n"

# Step 6: Custom welcome message
echo -e "${CYAN}Step 6: Enter a custom welcome message for when the bot starts (Optional)${NC}"
read -p "Message: " CUSTOM_WELCOME_MESSAGE
echo -e "${GREEN}Welcome message saved.${NC}\n"

echo -e "${YELLOW}Generating configuration files...${NC}"

# Generate environment file (bash format)
cat > environment << EOF
export BOT_TOKEN="${BOT_TOKEN}"
export LOGGING_COG_CHANNEL_ID="${LOGGING_CHANNEL_ID}"
export TLE_ADMIN="${ADMIN_ROLE}"
export TLE_MODERATOR="${MODERATOR_ROLE}"
EOF

# Generate .env file (Docker format)
cat > .env << EOF
BOT_TOKEN=${BOT_TOKEN}
LOGGING_COG_CHANNEL_ID=${LOGGING_CHANNEL_ID}
TLE_ADMIN=${ADMIN_ROLE}
TLE_MODERATOR=${MODERATOR_ROLE}
EOF

# Generate config.json file
cat > config.json << EOF
{
  "bot_prefix": "${BOT_PREFIX}",
  "custom_welcome_message": "${CUSTOM_WELCOME_MESSAGE}",
  "admin_role": "${ADMIN_ROLE}",
  "moderator_role": "${MODERATOR_ROLE}",
  "auto_cache_problemsets": true,
  "rating_roles_enabled": true,
  "starboard_enabled": true,
  "duel_enabled": true,
  "training_enabled": true,
  "lockout_enabled": true
}
EOF

echo -e "${GREEN}✔ environment created${NC}"
echo -e "${GREEN}✔ .env created${NC}"
echo -e "${GREEN}✔ config.json created${NC}"

echo -e "\n${CYAN}--- Summary ---${NC}"
echo -e "Admin Role: ${ADMIN_ROLE}"
echo -e "Moderator Role: ${MODERATOR_ROLE}"
echo -e "Prefix: ${BOT_PREFIX}"
echo -e "${CYAN}---------------${NC}\n"

echo -e "${GREEN}Setup complete! Next steps:${NC}"
echo -e "Run ${YELLOW}docker compose up -d${NC} to start your bot."
