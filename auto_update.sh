#!/bin/bash
# Auto-update script for TLE Bot on AWS
# Runs automatically via cron to keep the bot updated with GitHub changes.

cd "$(dirname "$0")"

echo "[$(date)] Checking for updates..."

# Fetch the latest changes from the remote repository
git fetch origin

# Get the current branch
BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Check if we are behind the remote branch
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/$BRANCH)

if [ "$LOCAL" != "$REMOTE" ]; then
    echo "[$(date)] Updates found! Pulling latest code..."
    
    # Pull the changes
    git pull origin $BRANCH
    
    echo "[$(date)] Rebuilding and restarting the bot..."
    # Rebuild and restart the docker container
    sudo docker-compose up -d --build
    
    echo "[$(date)] Update complete!"
else
    echo "[$(date)] Bot is up to date."
fi
