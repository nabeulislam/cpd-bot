#!/bin/bash
# AWS EC2 Ubuntu Deployment Script for TLE Bot
# Run this script on a fresh AWS EC2 instance (Ubuntu) to automatically install Docker and start the bot.

set -e

echo "Installing Docker and Docker Compose..."
sudo apt-get update -y
sudo apt-get install -y docker.io docker-compose

echo "Building and starting the bot..."
# Make sure the container restarts automatically if the server reboots
sudo docker-compose up -d --build

echo "Setting up auto-updater..."
chmod +x auto_update.sh
# Add to crontab if not already present
(crontab -l 2>/dev/null; echo "*/5 * * * * $(pwd)/auto_update.sh >> $(pwd)/auto_update.log 2>&1") | crontab -

echo "=========================================="
echo "Deployment Complete! 🚀"
echo "The bot is now running in the background."
echo "Auto-updates are configured to run every 5 minutes from GitHub."
echo "To view live logs, run: sudo docker-compose logs -f"
echo "=========================================="
