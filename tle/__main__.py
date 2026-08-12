import argparse
import asyncio
import distutils.util
import logging
import os
import discord
from logging.handlers import TimedRotatingFileHandler
from os import environ
from pathlib import Path

import seaborn as sns
from discord.ext import commands
from matplotlib import pyplot as plt

from tle import constants
from tle.util import codeforces_common as cf_common
from tle.util import discord_common, font_downloader



def setup():
    # Make required directories.
    for path in constants.ALL_DIRS:
        os.makedirs(path, exist_ok=True)

    # logging to console and file on daily interval
    logging.basicConfig(format='{asctime}:{levelname}:{name}:{message}', style='{',
                        datefmt='%d-%m-%Y %H:%M:%S', level=logging.INFO,
                        handlers=[logging.StreamHandler(),
                                  TimedRotatingFileHandler(constants.LOG_FILE_PATH, when='D',
                                                           backupCount=3, utc=True)])

    # matplotlib and seaborn
    plt.rcParams['figure.figsize'] = 7.0, 3.5
    sns.set()
    options = {
        'axes.edgecolor': '#A0A0C5',
        'axes.spines.top': False,
        'axes.spines.right': False,
    }
    sns.set_style('darkgrid', options)

    # Download fonts if necessary
    font_downloader.maybe_download()


async def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--nodb', action='store_true')
    args = parser.parse_args()

    token = environ.get('BOT_TOKEN')
    if not token:
        logging.error('Token required')
        return

    setup()

    logging.info(f'Bot prefix: {constants.BOT_PREFIX}')
    logging.info(f'Admin role: {constants.TLE_ADMIN}')
    logging.info(f'Moderator role: {constants.TLE_MODERATOR}')
    
    intents = discord.Intents.default()
    intents.members = True
    intents.message_content = True

    bot = commands.Bot(command_prefix=commands.when_mentioned_or(constants.BOT_PREFIX), intents=intents)
    bot.help_command = discord_common.TleHelp()
    cogs = [file.stem for file in Path('tle', 'cogs').glob('*.py')]
    for extension in cogs:
        await bot.load_extension(f'tle.cogs.{extension}')
    logging.info(f'Cogs loaded: {", ".join(bot.cogs)}')

    def no_dm_check(ctx):
        if ctx.guild is None:
            raise commands.NoPrivateMessage('Private messages not permitted.')
        return True

    # Restrict bot usage to inside guild channels only.
    bot.add_check(no_dm_check)

    async def create_missing_roles(guild):
        required_roles = [constants.TLE_ADMIN, constants.TLE_MODERATOR]
        for role_name in required_roles:
            if not discord.utils.get(guild.roles, name=role_name):
                try:
                    await guild.create_role(name=role_name, reason="TLE bot required role")
                    logging.info(f'Created missing role {role_name} in guild {guild.name}')
                except discord.Forbidden:
                    logging.warning(f'Missing permissions to create role {role_name} in guild {guild.name}')
                except discord.HTTPException as e:
                    logging.error(f'Failed to create role {role_name} in guild {guild.name}: {e}')

    @bot.event
    async def on_guild_join(guild):
        await create_missing_roles(guild)

    # cf_common.initialize needs to run first, so it must be set as the bot's
    # on_ready event handler rather than an on_ready listener.
    @discord_common.on_ready_event_once(bot)
    async def init():
        await cf_common.initialize(args.nodb)
        asyncio.create_task(discord_common.presence(bot))

        # Create missing roles in all guilds on startup
        for guild in bot.guilds:
            await create_missing_roles(guild)

        # Send custom welcome message if configured
        welcome_msg = constants.CUSTOM_WELCOME_MESSAGE
        if welcome_msg:
            channel_id = environ.get('LOGGING_COG_CHANNEL_ID')
            if channel_id:
                try:
                    channel = bot.get_channel(int(channel_id))
                    if channel:
                        await channel.send(f'🤖 {welcome_msg}')
                except (ValueError, Exception) as e:
                    logging.warning(f'Could not send welcome message: {e}')

        logging.info(f'Bot is ready! Prefix: {constants.BOT_PREFIX}')

    bot.add_listener(discord_common.bot_error_handler, name='on_command_error')
    await bot.start(token)


if __name__ == '__main__':
     asyncio.run(main())
