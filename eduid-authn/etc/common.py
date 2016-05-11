# -*- coding: utf-8 -*-
__author__ = 'lundberg'

import os

HERE = os.path.abspath(os.path.dirname(__file__))

MONGO_URI = 'mongodb://mongodb.docker'
SAML2_SETTINGS_MODULE = os.path.join(HERE, 'saml2_settings.py')

REDIS_HOST = 'redis.docker'
REDIS_PORT = 6379

SERVER_NAME = 'authn.docker:8080'
