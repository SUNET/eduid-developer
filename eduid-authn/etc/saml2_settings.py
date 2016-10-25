#!/usr/bin/env python
# -*- coding: utf-8 -*-
import saml2
from os import path

from saml2 import attributemaps


DEFAULT_ATTRIBUTEMAPS = path.dirname(attributemaps.__file__)

BASE_URL = 'http://dashboard.eduid.docker/services/authn'
SAML2DIR = path.dirname(__file__)

SAML_CONFIG = {
    # full path to the xmlsec1 binary programm
    'xmlsec_binary': '/usr/bin/xmlsec1',

    # your entity id, usually your subdomain plus the url to the metadata view
    'entityid': '%s/saml2-metadata' % BASE_URL,

    # directory with attribute mapping
    'attribute_map_dir': DEFAULT_ATTRIBUTEMAPS,

    # this block states what services we provide
    'service': {
        # we are just a lonely SP
        'sp': {
            'name': 'eduID Authn',
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
            # # This is commented to be compatible with simplesamlphp
            # # attributes that this project need to identify a user
            #'required_attributes': ['uid'],
            #
            # # attributes that may be useful to have but not required
            #'optional_attributes': ['eduPersonAffiliation'],

            # in this section the list of IdPs we talk to are defined
            'idp': {
                # we do not need a WAYF service since there is
                # only an IdP defined here. This IdP should be
                # present in our metadata

                # the keys of this dictionary are entity ids
                'http://idp.eduid.docker:8080/idp.xml': {
                    'single_sign_on_service': {
                        saml2.BINDING_HTTP_REDIRECT: 'http://idp.eduid.docker:8080/sso/redirect',
                    },
                    'single_logout_service': {
                        saml2.BINDING_HTTP_REDIRECT: 'http://idp.eduid.docker:8080/slo/redirect',
                    },
                },
            },
        },
    },

    # where the remote metadata is stored
    'metadata': {
        'local': [path.join(SAML2DIR, 'idp_metadata.xml')],
    },

    # set to 1 to output debugging information
    'debug': 1,

    # certificate
    'key_file': '/opt/eduid/etc/public-snakeoil.key',  # private part
    'cert_file': '/opt/eduid/etc/public-snakeoil.pem',  # public part


    # own metadata settings
    'contact_person': [
        {'given_name': 'Sysadmin',
         'sur_name': '',
         'company': 'eduID',
         'email_address': 'eduid-dev@SEGATE.SUNET.SE',
         'contact_type': 'technical'},
    ],
    # you can set multilanguage information here
    'organization': {
        'name': [('eduID', 'en')],
        'display_name': [('eduID', 'en')],
        'url': [('http://www./', 'en')],
    },
}

# Workaround for make_metadata.py or something
#
# File "/opt/eduid/local/lib/python2.7/site-packages/saml2/config.py", line 341, in load_file
#    return self.load(mod.CONFIG, metadata_construction)
# AttributeError: 'module' object has no attribute 'CONFIG'
CONFIG = SAML_CONFIG
