#!/bin/bash

# ==============================================================================
# TLE Discord Bot - AWS Deployment Script
# ==============================================================================

# Color definitions
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print banner
echo -e "${CYAN}"
cat << "EOF"
  _____  _      ______ 
 |_   _|| |    |  ____|
   | |  | |    | |__   
   | |  | |    |  __|  
   | |  | |____| |____ 
   \_/  |______|______|
                       
 AWS Deployment Script
EOF
echo -e "${NC}"

# Helper functions for printing
print_step() {
    echo -e "${CYAN}==>${NC} ${1}"
}

print_success() {
    echo -e "${GREEN}SUCCESS:${NC} ${1}"
}

print_warning() {
    echo -e "${YELLOW}WARNING:${NC} ${1}"
}

print_error() {
    echo -e "${RED}ERROR:${NC} ${1}"
}

# Ensure script is run from project root
cd "$(dirname "$0")"

# --- TEARDOWN MODE ---
if [[ "$1" == "--teardown" ]]; then
    print_step "Starting teardown..."
    REGION=${2:-us-east-1}
    
    # Get instance ID
    INSTANCE_ID=$(aws ec2 describe-instances --region "$REGION" --filters "Name=tag:Name,Values=TLE-Bot" "Name=instance-state-name,Values=running,pending,stopped" --query "Reservations[0].Instances[0].InstanceId" --output text)
    
    if [ "$INSTANCE_ID" != "None" ] && [ -n "$INSTANCE_ID" ]; then
        print_step "Terminating instance $INSTANCE_ID..."
        aws ec2 terminate-instances --region "$REGION" --instance-ids "$INSTANCE_ID"
        print_step "Waiting for instance to terminate..."
        aws ec2 wait instance-terminated --region "$REGION" --instance-ids "$INSTANCE_ID"
        print_success "Instance terminated."
    else
        print_warning "No TLE-Bot instance found."
    fi

    # Delete Security Group
    SG_ID=$(aws ec2 describe-security-groups --region "$REGION" --group-names tle-bot-sg --query "SecurityGroups[0].GroupId" --output text 2>/dev/null)
    if [ "$SG_ID" != "None" ] && [ -n "$SG_ID" ]; then
        print_step "Deleting Security Group tle-bot-sg ($SG_ID)..."
        aws ec2 delete-security-group --region "$REGION" --group-id "$SG_ID"
        print_success "Security Group deleted."
    fi

    # Delete Key Pair
    print_step "Deleting Key Pair tle-bot-key..."
    aws ec2 delete-key-pair --region "$REGION" --key-name tle-bot-key
    rm -f tle-bot-key.pem
    print_success "Key Pair deleted."
    
    print_success "Teardown complete!"
    exit 0
fi

# --- PREREQUISITES ---
print_step "Checking prerequisites..."

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    print_warning "AWS CLI is not installed."
    read -p "Would you like to install AWS CLI v2 now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_step "Detecting OS..."
        OS="$(uname -s)"
        case "${OS}" in
            Linux*)
                print_step "Installing AWS CLI for Linux..."
                curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                unzip awscliv2.zip
                sudo ./aws/install
                rm -rf awscliv2.zip aws/
                ;;
            Darwin*)
                print_step "Installing AWS CLI for Mac (Homebrew required)..."
                if ! command -v brew &> /dev/null; then
                    print_error "Homebrew not found. Please install Homebrew or AWS CLI manually."
                    exit 1
                fi
                brew install awscli
                ;;
            *)
                print_error "Unsupported OS: ${OS}. Please install AWS CLI manually."
                exit 1
                ;;
        esac
        
        if ! command -v aws &> /dev/null; then
            print_error "AWS CLI installation failed."
            exit 1
        fi
        print_success "AWS CLI installed successfully."
    else
        print_error "AWS CLI is required. Exiting."
        exit 1
    fi
else
    print_success "AWS CLI is installed."
fi

# Check AWS Credentials
if ! aws sts get-caller-identity &> /dev/null; then
    print_warning "AWS credentials are not configured."
    echo "You need your AWS Access Key ID and Secret Access Key."
    echo "Get them here: https://console.aws.amazon.com/iam/home?#/security_credentials"
    read -p "Press Enter to run 'aws configure'..."
    aws configure
    
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials still not valid. Exiting."
        exit 1
    fi
fi
print_success "AWS credentials are valid."

# --- DEPLOYMENT ---
echo
print_step "AWS Region Selection"
echo "Popular regions: us-east-1 (N. Virginia), us-east-2 (Ohio), us-west-2 (Oregon), eu-west-1 (Ireland)"
read -p "Enter AWS Region [us-east-1]: " REGION
REGION=${REGION:-us-east-1}
print_step "Using region: $REGION"

# Get User IP for Security Group
MY_IP=$(curl -s http://checkip.amazonaws.com)
if [ -z "$MY_IP" ]; then
    print_error "Could not determine your public IP."
    exit 1
fi
print_step "Your public IP is $MY_IP"

# Create Security Group
SG_NAME="tle-bot-sg"
SG_ID=$(aws ec2 describe-security-groups --region "$REGION" --group-names "$SG_NAME" --query "SecurityGroups[0].GroupId" --output text 2>/dev/null)

if [ "$?" -ne 0 ] || [ -z "$SG_ID" ]; then
    print_step "Creating Security Group ($SG_NAME)..."
    SG_ID=$(aws ec2 create-security-group --region "$REGION" --group-name "$SG_NAME" --description "Security group for TLE Bot" --query "GroupId" --output text)
    aws ec2 authorize-security-group-ingress --region "$REGION" --group-id "$SG_ID" --protocol tcp --port 22 --cidr "$MY_IP/32"
    print_success "Security Group created ($SG_ID)."
else
    print_success "Security Group $SG_NAME already exists ($SG_ID)."
fi

# Create Key Pair
KEY_NAME="tle-bot-key"
if [ ! -f "${KEY_NAME}.pem" ]; then
    print_step "Creating EC2 Key Pair ($KEY_NAME)..."
    aws ec2 create-key-pair --region "$REGION" --key-name "$KEY_NAME" --query "KeyMaterial" --output text > "${KEY_NAME}.pem"
    chmod 400 "${KEY_NAME}.pem"
    print_success "Key Pair saved to ${KEY_NAME}.pem"
else
    print_success "Key Pair ${KEY_NAME}.pem already exists locally."
fi

# Get AL2023 AMI for region
print_step "Finding Amazon Linux 2023 AMI..."
AMI_ID=$(aws ssm get-parameters --region "$REGION" --names /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64 --query 'Parameters[0].[Value]' --output text)

# Launch Instance
print_step "Launching t3.micro EC2 Instance..."
INSTANCE_ID=$(aws ec2 run-instances \
    --region "$REGION" \
    --image-id "$AMI_ID" \
    --instance-type t3.micro \
    --key-name "$KEY_NAME" \
    --security-group-ids "$SG_ID" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=TLE-Bot}]" \
    --query "Instances[0].InstanceId" \
    --output text)

print_step "Waiting for instance to be running..."
aws ec2 wait instance-running --region "$REGION" --instance-ids "$INSTANCE_ID"

INSTANCE_IP=$(aws ec2 describe-instances --region "$REGION" --instance-ids "$INSTANCE_ID" --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
print_success "Instance is running! Public IP: $INSTANCE_IP"

print_step "Waiting for status checks to pass and SSH to become available (this might take a minute)..."
aws ec2 wait instance-status-ok --region "$REGION" --instance-ids "$INSTANCE_ID"
sleep 15 # Give SSH daemon a moment to start

# SCP Files
print_step "Copying project files to instance..."
# Create archive to avoid transferring .git and virtualenvs
tar -czf tle-deploy.tar.gz --exclude='.git' --exclude='venv' --exclude='__pycache__' .
scp -i "${KEY_NAME}.pem" -o StrictHostKeyChecking=no tle-deploy.tar.gz ec2-user@${INSTANCE_IP}:~/
rm tle-deploy.tar.gz

# Remote Setup via SSH
print_step "Connecting via SSH to run setup..."
ssh -i "${KEY_NAME}.pem" -o StrictHostKeyChecking=no ec2-user@${INSTANCE_IP} << 'EOF'
    set -e
    echo "==> Extracting project..."
    mkdir -p cpdbot
    tar -xzf tle-deploy.tar.gz -C cpdbot/
    rm tle-deploy.tar.gz
    cd cpdbot
    
    echo "==> Installing Docker..."
    sudo dnf update -y
    sudo dnf install -y docker
    sudo systemctl enable --now docker
    sudo usermod -aG docker ec2-user
    
    echo "==> Installing Docker Compose..."
    sudo mkdir -p /usr/local/lib/docker/cli-plugins
    sudo curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
    sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
EOF

print_step "Running interactive setup.sh..."
ssh -i "${KEY_NAME}.pem" -o StrictHostKeyChecking=no -t ec2-user@${INSTANCE_IP} 'cd cpdbot && bash setup.sh'

print_step "Starting containers..."
ssh -i "${KEY_NAME}.pem" -o StrictHostKeyChecking=no ec2-user@${INSTANCE_IP} 'cd cpdbot && sg docker -c "docker compose up -d"'

# Summary
echo
echo -e "${GREEN}================================================================${NC}"
echo -e "${GREEN}               DEPLOYMENT COMPLETED SUCCESSFULLY                ${NC}"
echo -e "${GREEN}================================================================${NC}"
echo
echo -e "Your TLE Bot is running on AWS EC2!"
echo -e "Instance IP: ${CYAN}${INSTANCE_IP}${NC}"
echo
echo -e "To connect to your instance:"
echo -e "${CYAN}ssh -i \"${KEY_NAME}.pem\" ec2-user@${INSTANCE_IP}${NC}"
echo
echo -e "Useful commands (run over SSH):"
echo -e "  View Logs:      ${CYAN}cd cpdbot && docker compose logs -f${NC}"
echo -e "  Restart Bot:    ${CYAN}cd cpdbot && docker compose restart${NC}"
echo -e "  Stop Bot:       ${CYAN}cd cpdbot && docker compose down${NC}"
echo
echo -e "Estimated Cost:"
echo -e "  Instance: t3.micro (~\$8.50/month, free tier eligible)"
echo
echo -e "To teardown completely:"
echo -e "${CYAN}./deploy-aws.sh --teardown ${REGION}${NC}"
echo
