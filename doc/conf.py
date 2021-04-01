import sys
import os

sys.path.insert(0, os.path.abspath('..'))

master_doc = 'index'

source_suffix = '.rst'

project = u'Monitoring'

exclude_patterns = [
    'conf.py',
    'monitoring/images',
    'requirements.txt',
    'locale',
]

language = 'en'
locale_dirs = ['./locale']
gettext_compact = False
gettext_location = False
