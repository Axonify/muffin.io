import os, logging

DEBUG = False

if os.environ.get('SERVER_SOFTWARE','').startswith('Development'):
    DEBUG = True
    logging.debug("[*] Debug info activated")
