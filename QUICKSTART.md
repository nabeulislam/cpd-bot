# 🚀 TLE Bot — Quick Start Guide

Get your competitive programming Discord bot running in minutes.

---

## Step 0: Create a Discord Bot (if you haven't already)

1. Go to [Discord Developer Portal](https://discord.com/developers/applications)
2. Click **"New Application"** → Name it (e.g., "TLE Bot") → Create
3. Go to **Bot** tab → Click **"Add Bot"**
4. Copy the **Bot Token** (you'll need this in Step 1)
5. **IMPORTANT**: Scroll down and enable these intents:
   - ✅ **Server Members Intent**
   - ✅ **Message Content Intent**
6. Go to **OAuth2 → URL Generator**:
   - Scopes: `bot`
   - Permissions: `Send Messages`, `Manage Roles`, `Read Message History`, `Embed Links`, `Attach Files`, `Add Reactions`, `Use External Emojis`
7. Copy the generated URL → Open it → Add bot to your server

---

## Step 1: Run the Setup Wizard

```bash
git clone https://github.com/Denjell/TLE.git
cd TLE
./setup.sh
```

The wizard will ask you for:
- 🔑 Your **Bot Token**
- 📝 Your **Logging Channel ID** (right-click a channel → Copy Channel ID)
- ⚙️ Optional: Custom prefix, role names, welcome message

---

## Step 2: Deploy

### Option A: Docker (Recommended — one command)

```bash
docker compose up -d
```

That's it. Your bot is running. ✅

**Useful commands:**
```bash
docker compose logs -f        # View live logs
docker compose restart        # Restart the bot
docker compose down           # Stop the bot
docker compose up -d --build  # Rebuild after code changes
```

### Option B: Deploy to AWS (if you don't have a server)

```bash
./deploy-aws.sh
```

This will:
1. Install AWS CLI if needed
2. Create an EC2 instance (t3.micro — ~$8.50/month, free tier eligible)
3. Install Docker on it
4. Deploy your bot
5. Give you SSH access

**Quick alternative — paste in EC2 User Data:**
See `aws-userdata.sh` for a script you can paste into the EC2 launch wizard's "User Data" field for fully automated setup.

### Option C: Run directly (no Docker)

```bash
# Install system dependencies (Ubuntu/Debian)
sudo apt-get install -y libcairo2-dev libgirepository1.0-dev libpango1.0-dev \
  pkg-config python3-dev gir1.2-pango-1.0 libjpeg-dev zlib1g-dev

# Install Python dependencies
pip install -r requirements.txt

# Run
./run.sh
```

---

## Step 3: Customize Your Bot

Edit `config.json` to change bot behavior — **no code editing needed!**

```json
{
  "bot_prefix": ";",
  "custom_welcome_message": "TLE Bot is online! Type ;help to get started.",
  "admin_role": "Admin",
  "moderator_role": "Moderator",
  "auto_cache_problemsets": true,
  "rating_roles_enabled": true,
  "starboard_enabled": true,
  "duel_enabled": true,
  "training_enabled": true,
  "lockout_enabled": true
}
```

**What you can customize:**

| Setting | What it does | Default |
|---------|-------------|---------|
| `bot_prefix` | Command prefix (e.g., `!`, `.`, `>`) | `;` |
| `custom_welcome_message` | Message sent when bot starts | (empty) |
| `admin_role` | Discord role for admin commands | `Admin` |
| `moderator_role` | Discord role for mod commands | `Moderator` |
| `auto_cache_problemsets` | Auto-cache CF problems on start | `true` |
| `rating_roles_enabled` | Auto-assign rank-based roles | `true` |
| `starboard_enabled` | Enable ⭐ starboard feature | `true` |
| `duel_enabled` | Enable 1v1 duel commands | `true` |
| `training_enabled` | Enable training sessions | `true` |
| `lockout_enabled` | Enable lockout rounds | `true` |

After editing, restart: `docker compose restart`

---

## Step 4: Set Up Your Discord Server

Create these roles in your Discord server for the rating system to work:

- `Unrated`
- `Newbie`
- `Pupil`
- `Specialist`
- `Expert`
- `Candidate Master`
- `Master`
- `International Master`
- `Grandmaster`
- `International Grandmaster`
- `Legendary Grandmaster`

Also create the `Admin` and `Moderator` roles (or whatever you named them in config).

---

## First-Time Commands

Once your bot is running in Discord:

```
;cache problemsets all     # Cache problem data (takes ~10 min, run once)
;handle set YourCFHandle   # Link your Codeforces account
;help                      # See all available commands
```

---

## Troubleshooting

### Bot doesn't come online
- Check your token is correct: `docker compose logs`
- Make sure **Server Members Intent** and **Message Content Intent** are enabled in the Discord Developer Portal

### Bot is online but doesn't respond
- Check the prefix: try `@BotName help` (mention works regardless of prefix)
- Make sure you're not in a DM (bot only works in server channels)

### Docker build fails
- Make sure Docker is running: `docker info`
- Try rebuilding: `docker compose build --no-cache`

### AWS deployment issues
- Check instance status: `aws ec2 describe-instances --filters "Name=tag:Name,Values=TLE-Bot"`
- SSH in to check: `ssh -i tle-bot-key.pem ec2-user@<IP>`
- View cloud-init logs: `sudo cat /var/log/tle-setup.log`

---

## Files Overview

| File | Purpose |
|------|---------|
| `setup.sh` | Interactive setup wizard |
| `config.json` | Bot customization (prefix, messages, features) |
| `.env` | Secret config (token, channel ID) |
| `docker-compose.yml` | One-command Docker deployment |
| `deploy-aws.sh` | AWS EC2 auto-deployment |
| `aws-userdata.sh` | Paste-in-EC2 automated script |
| `Dockerfile` | Container build recipe |

---

## Updating the Bot

```bash
git pull
docker compose up -d --build
```

## Stopping the Bot

```bash
docker compose down          # Stop locally
./deploy-aws.sh --teardown   # Terminate AWS instance
```
