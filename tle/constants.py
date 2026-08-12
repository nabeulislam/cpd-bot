import json
import os

# ─── Directories ───────────────────────────────────────────────────────────────
DATA_DIR = 'data'
LOGS_DIR = 'logs'

ASSETS_DIR = os.path.join(DATA_DIR, 'assets')
DB_DIR = os.path.join(DATA_DIR, 'db')
MISC_DIR = os.path.join(DATA_DIR, 'misc')
TEMP_DIR = os.path.join(DATA_DIR, 'temp')

USER_DB_FILE_PATH = os.path.join(DB_DIR, 'user.db')
CACHE_DB_FILE_PATH = os.path.join(DB_DIR, 'cache.db')

FONTS_DIR = os.path.join(ASSETS_DIR, 'fonts')

NOTO_SANS_CJK_BOLD_FONT_PATH = os.path.join(FONTS_DIR, 'NotoSansCJK-Bold.ttc')
NOTO_SANS_CJK_REGULAR_FONT_PATH = os.path.join(FONTS_DIR, 'NotoSansCJK-Regular.ttc')

CONTEST_WRITERS_JSON_FILE_PATH = os.path.join(MISC_DIR, 'contest_writers.json')

LOG_FILE_PATH = os.path.join(LOGS_DIR, 'tle.log')

ALL_DIRS = (attrib_value for attrib_name, attrib_value in list(globals().items())
            if attrib_name.endswith('DIR'))

# ─── Config from config.json (easy customization, no code editing needed) ─────
CONFIG_FILE = 'config.json'
_DEFAULT_CONFIG = {
    'bot_prefix': ';',
    'custom_welcome_message': '',
    'admin_role': 'Admin',
    'moderator_role': 'Moderator',
    'auto_cache_problemsets': True,
    'rating_roles_enabled': True,
    'starboard_enabled': True,
    'duel_enabled': True,
    'training_enabled': True,
    'lockout_enabled': True,
}

def _load_config():
    """Load config.json if it exists, falling back to defaults."""
    config = dict(_DEFAULT_CONFIG)
    if os.path.isfile(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, 'r') as f:
                user_config = json.load(f)
            config.update(user_config)
        except (json.JSONDecodeError, IOError) as e:
            print(f'[WARNING] Could not load {CONFIG_FILE}: {e}. Using defaults.')
    return config

CONFIG = _load_config()

# ─── Resolved settings (env vars override config.json) ────────────────────────
TLE_ADMIN = os.environ.get('TLE_ADMIN', CONFIG['admin_role'])
TLE_MODERATOR = os.environ.get('TLE_MODERATOR', CONFIG['moderator_role'])
BOT_PREFIX = CONFIG['bot_prefix']
CUSTOM_WELCOME_MESSAGE = CONFIG['custom_welcome_message']
