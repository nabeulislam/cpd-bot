#!/bin/bash
# AWS EC2 Ubuntu Deployment Script for TLE Bot
# Run this script on a fresh AWS EC2 instance (Ubuntu) to automatically install Docker and start the bot.

set -e

echo "Installing Docker and Docker Compose..."
sudo apt-get update -y
sudo apt-get install -y docker.io docker-compose-v2

echo ""
echo "=========================================="
echo "    TLE Bot - Interactive Setup Wizard"
echo "=========================================="
echo ""

if [ ! -f .env ]; then
    read -p "Enter your Discord Bot Token: " BOT_TOKEN
    read -p "Enter your Logging Channel ID: " LOGGING_ID
    
    echo "BOT_TOKEN=$BOT_TOKEN" > .env
    echo "LOGGING_COG_CHANNEL_ID=$LOGGING_ID" >> .env
    echo "Created .env file!"
else
    echo ".env file already exists. Skipping token prompt."
fi

echo ""
echo "Building and starting the bot..."
# Make sure the container restarts automatically if the server reboots
sudo docker compose up -d --build

echo "Setting up auto-updater..."
chmod +x auto_update.sh
# Add to crontab if not already present
(crontab -l 2>/dev/null; echo "*/5 * * * * $(pwd)/auto_update.sh >> $(pwd)/auto_update.log 2>&1") | crontab -

echo "=========================================="
echo "Deployment Complete! 🚀"
echo "The bot is now running in the background."
echo "Auto-updates are configured to run every 5 minutes from GitHub."
echo "To view live logs, run: sudo docker compose logs -f"
echo "=========================================="
