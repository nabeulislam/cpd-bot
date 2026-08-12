import logging
import os
import urllib.request

from zipfile import ZipFile
from io import BytesIO

from tle import constants

URL_BASE = 'https://github.com/notofonts/noto-cjk/raw/main/Sans/OTC/'
FONTS = [constants.NOTO_SANS_CJK_BOLD_FONT_PATH,
         constants.NOTO_SANS_CJK_REGULAR_FONT_PATH]

logger = logging.getLogger(__name__)


def _download(font_path):
    font = os.path.basename(font_path)
    logger.info(f'Downloading font `{font}`.')
    req = urllib.request.Request(f'{URL_BASE}{font}', headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req) as resp:
        with open(font_path, 'wb') as f:
            f.write(resp.read())


def maybe_download():
    for font_path in FONTS:
        if not os.path.isfile(font_path):
            _download(font_path)
