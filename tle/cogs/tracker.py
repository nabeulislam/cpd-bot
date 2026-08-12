import asyncio
import logging
from datetime import datetime

import discord
from discord.ext import commands, tasks

from tle import constants
from tle.util import codeforces_api as cf
from tle.util import codeforces_common as cf_common
from tle.util import discord_common

class Tracker(commands.Cog):
    def __init__(self, bot):
        self.bot = bot
        self.logger = logging.getLogger(self.__class__.__name__)
        self.track_solves.start()

    def cog_unload(self):
        self.track_solves.cancel()

    @commands.group(brief='Tracker commands', invoke_without_command=True)
    async def tracker(self, ctx):
        """Commands to configure the daily solved problem tracker."""
        await ctx.send_help(ctx.command)

    @tracker.command(brief='Set the tracker channel')
    @commands.has_any_role(constants.TLE_ADMIN, constants.TLE_MODERATOR)
    async def add(self, ctx, channel: discord.TextChannel):
        """Set the channel where new solved problems will be posted."""
        cf_common.user_db.set_tracker_channel(ctx.guild.id, channel.id)
        await ctx.send(embed=discord_common.embed_success(f'Tracker channel set to {channel.mention}'))

    @tracker.command(brief='Remove the tracker channel')
    @commands.has_any_role(constants.TLE_ADMIN, constants.TLE_MODERATOR)
    async def remove(self, ctx):
        """Stop posting new solved problems in this server."""
        cf_common.user_db.clear_tracker_channel(ctx.guild.id)
        await ctx.send(embed=discord_common.embed_success('Tracker channel removed'))

    @tasks.loop(minutes=1)
    async def track_solves(self):
        try:
            tracker_channels = cf_common.user_db.get_tracker_channels()
            if not tracker_channels:
                return

            guild_to_channel = {guild_id: channel_id for guild_id, channel_id in tracker_channels}
            
            # Aggregate all handles to track and their associated guilds
            handle_to_guilds = {}
            for guild_id in guild_to_channel.keys():
                guild_handles = cf_common.user_db.get_handles_for_guild(guild_id)
                for user_id, handle in guild_handles:
                    if handle not in handle_to_guilds:
                        handle_to_guilds[handle] = []
                    handle_to_guilds[handle].append(guild_id)

            for handle, guilds in handle_to_guilds.items():
                last_sub_id = cf_common.user_db.get_tracker_last_sub(handle)
                
                try:
                    subs = await cf.user.status(handle=handle, count=20)
                    await asyncio.sleep(1.5) # respect rate limits
                except Exception as e:
                    self.logger.error(f'Failed to fetch status for {handle}: {e}')
                    continue

                if not subs:
                    continue
                new_subs = [s for s in subs if s.id > last_sub_id and (s.verdict in ('OK', 'PARTIAL') or (s.points is not None and s.points > 0))]                
                judged_subs = [s for s in subs if s.verdict not in (None, 'TESTING', 'SUBMITTED')]
                max_sub_id = max((s.id for s in judged_subs), default=last_sub_id)
                if max_sub_id > last_sub_id:
                    cf_common.user_db.set_tracker_last_sub(handle, max_sub_id)
                
                if not new_subs or last_sub_id == 0:
                    # If last_sub_id was 0, it means it's our first time checking this user.
                    # We just seed their max_sub_id and skip posting their entire history.
                    continue

                user = cf_common.user_db.fetch_cf_user(handle)
                icon_url = user.titlePhoto if user else ""
                if not icon_url:
                    icon_url = discord.Embed.Empty

                for sub in sorted(new_subs, key=lambda s: s.id):
                    prob = sub.problem
                    
                    embed = discord.Embed(color=0x5865F2) # Match Discord default app color
                    embed.set_author(name=handle, icon_url=icon_url)
                    
                    if prob.contestId and prob.contestId >= 100000:
                        prob_link = f'https://codeforces.com/gym/{prob.contestId}/problem/{prob.index}'
                    else:
                        prob_link = f'https://codeforces.com/contest/{prob.contestId}/problem/{prob.index}'
                        
                    name = prob.name
                    if sub.points is not None:
                        name += f' ({sub.points} points)'
                        
                    embed.add_field(name='Solved', value=f'[# {name}]({prob_link})', inline=True)
                    embed.add_field(name='Rating', value=str(prob.rating) if prob.rating else 'XXXX', inline=True)
                    
                    tags = "|| " + ", ".join(prob.tags) + " ||" if prob.tags else "None"
                    embed.add_field(name='Tags', value=tags, inline=True)
                    
                    embed.set_footer(text=datetime.now().strftime("%m/%d/%y, %I:%M %p"))

                    for guild_id in guilds:
                        channel_id = guild_to_channel.get(guild_id)
                        if not channel_id: continue
                        channel = self.bot.get_channel(channel_id)
                        if channel:
                            try:
                                await channel.send(embed=embed)
                            except Exception as e:
                                self.logger.error(f'Failed to send solve embed to {channel_id}: {e}')

        except Exception as e:
            self.logger.error(f'Error in track_solves loop: {e}')

    @track_solves.before_loop
    async def before_track_solves(self):
        await self.bot.wait_until_ready()

async def setup(bot):
    await bot.add_cog(Tracker(bot))
