#!/usr/bin/env python
# -*- coding: utf-8 -*-
import saml2
from os import path

from saml2 import attributemaps


DEFAULT_ATTRIBUTEMAPS = path.dirname(attributemaps.__file__)

BASE_URL = 'http://eidas.eduid.docker:8080'
SAML2DIR = path.dirname(__file__)

SAML_CONFIG = {
    # full path to the xmlsec1 binary programm
    'xmlsec_binary': '/usr/bin/xmlsec1',

    # your entity id, usually your subdomain plus the url to the metadata view
    'entityid': '%s/saml2-metadata' % BASE_URL,

    # directory with attribute mapping
    'attribute_map_dir': DEFAULT_ATTRIBUTEMAPS,
    'allow_unknown_attributes': True,

    # this block states what services we provide
    'service': {
        # we are just a lonely SP
        'sp': {
            'name': 'eduID Dev eIDAS SP',
            'endpoints': {
                # url and binding to the assetion consumer service view
                # do not change the binding or service name
                'assertion_consumer_service': [
                    ('%s/saml2-acs' % BASE_URL,
                     saml2.BINDING_HTTP_POST),
                ],
                # url and binding to the single logout service view
                # do not change the binding or service name
                'single_logout_service': [
                    ('%s/logout' % BASE_URL,
                     saml2.BINDING_HTTP_REDIRECT),
                ],
            },
            # required attributes
            'required_attributes': ['personalIdentityNumber', 'DateOfBirth'],
            # attributes that may be useful to have but not required
            'optional_attributes': ['displayName', 'givenName', 'sn'],

            # eIDAS specific
            'sp_type': 'public',
            "sp_type_in_metadata": True,
            'requested_attributes': [
                {
                    "friendly_name": "personalIdentityNumber",
                    "required": True,
                },
                {
                    "friendly_name": "DateOfBirth",
                    "required": True,
                },
                {
                    "friendly_name": "displayName",
                    "required": False,
                },
                {
                    "friendly_name": "givenName",
                    "required": False,
                },
                {
                    "friendly_name": "sn",
                    "required": False,
                },
            ],

            # Sign authn request
            'authn_requests_signed': True,
            # Require signed authn response
            'want_response_signed': True,
        },
    },

    # where the remote metadata is stored
    'metadata': {
        'remote': [{'url': 'http://eid.svelegtest.se/metadata/feed', 'cert': '/opt/eduid/etc/sandbox-metadata-cert.crt'}],
        #'local': [path.join(SAML2DIR, 'idp_metadata.xml')],
    },

    # set to 1 to output debugging information
    'debug': 1,

    # certificate
    'key_file': '/opt/eduid/etc/eidas1-dev-sp-key.pem',  # private part
    'cert_file': '/opt/eduid/etc/eidas1-dev-sp-cert.pem',  # public part
    'encryption_keypairs': [
            {
                'key_file' :  '/opt/eduid/etc/eidas1-dev-sp-key.pem',
                'cert_file' : '/opt/eduid/etc/eidas1-dev-sp-cert.pem',
            }
    ],

    # own metadata settings
    'contact_person': [
        {'given_name': 'Sysadmin',
         'sur_name': '',
         'company': 'eduID',
         'email_address': 'feedback@eduid.se',
         'contact_type': 'technical'},
    ],
    # you can set multilanguage information here
    'organization': {
        'name': [('eduID Dev', 'en')],
        'display_name': [('eduID Dev', 'en')],
        'url': [('http://www.dev.eduid.se/', 'en')],
    },
}

# Workaround for make_metadata.py or something
#
# File "/opt/eduid/local/lib/python2.7/site-packages/saml2/config.py", line 341, in load_file
#    return self.load(mod.CONFIG, metadata_construction)
# AttributeError: 'module' object has no attribute 'CONFIG'
CONFIG = SAML_CONFIG
