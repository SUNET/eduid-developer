#!/usr/bin/env python

import saml2
from os import path

BASE_URL = "https://dashboard.eduid.docker/services/authn"
METADATA_DIR = path.dirname(__file__)

SAML_CONFIG = {
    # full path to the xmlsec1 binary programm
    "xmlsec_binary": "/usr/bin/xmlsec1",
    # your entity id, usually your subdomain plus the url to the metadata view
    "entityid": f"{BASE_URL}/saml2-metadata",
    "allow_unknown_attributes": True,
    "service": {
        # we are just a lonely SP
        "sp": {
            "name": "eduID Authn",
            "endpoints": {
                # url and binding to the assetion consumer service view
                # do not change the binding or service name
                "assertion_consumer_service": [
                    (f"{BASE_URL}/saml2-acs", saml2.BINDING_HTTP_POST),
                ],
                # url and binding to the single logout service view
                # do not change the binding or service name
                "single_logout_service": [
                    (f"{BASE_URL}/logout", saml2.BINDING_HTTP_REDIRECT),
                ],
            },
            # # This is commented to be compatible with simplesamlphp
            # # attributes that this project need to identify a user
            #'required_attributes': ['uid'],
            #
            # # attributes that may be useful to have but not required
            #'optional_attributes': ['eduPersonAffiliation'],
            # in this section the list of IdPs we talk to are defined
            "idp": {
                # we do not need a WAYF service since there is only an IdP defined here. This IdP should be
                # present in our metadata. The keys of this dictionary are entity ids.
                "https://idp.eduid.docker/idp.xml": {
                    "single_sign_on_service": {
                        saml2.BINDING_HTTP_REDIRECT: "https://idp.eduid.docker/sso/redirect",
                    },
                    "single_logout_service": {
                        saml2.BINDING_HTTP_REDIRECT: "https://idp.eduid.docker/slo/redirect",
                    },
                },
            },
        },
    },
    # where the remote metadata is stored
    "metadata": {
        "local": [path.join(METADATA_DIR, "idp_metadata.xml")],
    },
    # Enable debug logging
    "debug": True,
    # certificate
    "key_file": "/opt/eduid/etc/public-snakeoil.key",  # private part
    "cert_file": "/opt/eduid/etc/public-snakeoil.pem",  # public part
    # own metadata settings
    "contact_person": [
        {
            "given_name": "Sysadmin",
            "sur_name": "",
            "company": "eduID",
            "email_address": "eduid-dev@SEGATE.SUNET.SE",
            "contact_type": "technical",
        },
    ],
    # you can set multilanguage information here
    "organization": {
        "name": [("eduID", "en")],
        "display_name": [("eduID", "en")],
        "url": [("http://www./", "en")],
    },
}

# Workaround for make_metadata.py or something
#
# File "/opt/eduid/local/lib/python2.7/site-packages/saml2/config.py", line 341, in load_file
#    return self.load(mod.CONFIG, metadata_construction)
# AttributeError: 'module' object has no attribute 'CONFIG'
CONFIG = SAML_CONFIG
