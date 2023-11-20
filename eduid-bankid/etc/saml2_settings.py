#!/usr/bin/env python
# -*- coding: utf-8 -*-
import saml2
from os import path

from saml2 import attributemaps


DEFAULT_ATTRIBUTEMAPS = path.dirname(attributemaps.__file__)

BASE_URL = 'https://bankid.eduid.docker'
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
            'name': 'eduID Dev BankID SP',
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
            # set attributes as optional to be able to catch missing attributes in our service
            'optional_attributes': [
                'personalIdentityNumber',
                'displayName',
                'givenName',
                'sn',
                'transactionIdentifier',
                'authContextParams',
                ],

            # Sign authn request
            'authn_requests_signed': True,
            # Require signed authn response
            'want_response_signed': True,
            'name': 'bankid_local',
        },
    },

    # where the remote metadata is stored
    'metadata': {
        'mdq': [{'url': 'https://mds.swamid.se/qa/', 'freshness_period': 'P0Y0M0DT0H10M0S'}],
    },

    # set to 1 to output debugging information
    'debug': 1,

    # accept a time difference of 1 min
    'accepted_time_diff': 60,

    # certificate
    'key_file': '/opt/eduid/etc/saml.key',  # private part
    'cert_file': '/opt/eduid/etc/saml.pem',  # public part
    'encryption_keypairs': [
            {
                'key_file' :  '/opt/eduid/etc/saml.key',
                'cert_file' : '/opt/eduid/etc/saml.pem',
            }
    ],

    # own metadata settings
    'contact_person': [
        {'given_name': 'Johan',
         'sur_name': 'Lundberg',
         'company': 'Sunet',
         'email_address': 'feedback@eduid.se',
         'contact_type': 'technical'},
    ],
    # you can set multilanguage information here
    'organization': {
        'name': [('Sunet', 'en')],
        'display_name': [('Sunet', 'en')],
        'url': [('https://www.sunet.se/', 'en')],
    },
}

# Workaround for make_metadata.py or something
#
# File "/opt/eduid/local/lib/python2.7/site-packages/saml2/config.py", line 341, in load_file
#    return self.load(mod.CONFIG, metadata_construction)
# AttributeError: 'module' object has no attribute 'CONFIG'
CONFIG = SAML_CONFIG
