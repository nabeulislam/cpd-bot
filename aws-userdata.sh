#!/bin/bash

# ==============================================================================
# TLE Discord Bot - EC2 User Data (cloud-init) Script
# ==============================================================================
#
# INSTRUCTIONS FOR USE:
# 1. Go to EC2 Console > Launch Instance
# 2. Choose Amazon Linux 2023 AMI
# 3. Choose instance type (t3.micro is recommended)
# 4. Scroll down to Advanced Details > User Data
# 5. Paste this entire script into the User Data field
# 6. Launch the instance
# 7. Wait ~3 minutes, then SSH into the instance
# 8. Run: cd /opt/TLE && nano .env (fill in your DISCORD_TOKEN)
# 9. Run: docker compose up -d
# ==============================================================================

# Redirect all output to log file
exec > >(tee /var/log/tle-setup.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting TLE Bot User Data Setup..."

# Update packages
dnf update -y

# Install Git
dnf install -y git

# Install Docker
dnf install -y docker
systemctl enable --now docker
usermod -aG docker ec2-user

# Install Docker Compose (V2 plugin)
mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# Setup Project Directory
INSTALL_DIR="/opt/TLE"
echo "Cloning repository to $INSTALL_DIR..."
# NOTE: Replace the URL with your actual repository URL if it is private or a different fork
git clone https://github.com/Denjell/TLE.git "$INSTALL_DIR"

cd "$INSTALL_DIR"

# Create a placeholder .env file
echo "Creating placeholder .env file..."
cat << 'EOF' > .env
BOT_TOKEN=your_discord_bot_token_here
LOGGING_COG_CHANNEL_ID=your_channel_id_here
EOF

# Fix permissions
chown -R ec2-user:ec2-user "$INSTALL_DIR"

echo "Setup completed successfully."
echo "Please SSH in, update /opt/TLE/.env, and run 'docker compose up -d'"

