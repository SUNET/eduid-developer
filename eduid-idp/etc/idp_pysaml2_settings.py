#!/usr/bin/env python
from saml2 import BINDING_HTTP_REDIRECT
from saml2 import BINDING_HTTP_POST
from saml2 import BINDING_SOAP
from saml2.saml import NAME_FORMAT_URI
from saml2.saml import NAMEID_FORMAT_TRANSIENT
from saml2.saml import NAMEID_FORMAT_PERSISTENT

BASE = 'http://idp.docker:8080'

CONFIG = {
    "entityid": "%s/idp.xml" % BASE,
    "description": "eduID LOCAL TEST identity provider",
    "service": {
        "idp": {
            "name": "eduID LOCAL TEST IdP",
            "endpoints": {
                "single_sign_on_service": [
                    ("%s/sso/redirect" % BASE, BINDING_HTTP_REDIRECT),
                    ("%s/sso/post" % BASE, BINDING_HTTP_POST),
                ],
                "single_logout_service": [
                    ("%s/slo/soap" % BASE, BINDING_SOAP),
                    ("%s/slo/post" % BASE, BINDING_HTTP_POST),
                    ("%s/slo/redirect" % BASE, BINDING_HTTP_REDIRECT)
                ],
            },
            "policy": {
                "default": {
                    "lifetime": {"minutes": 5},
                    "attribute_restrictions": None, # means all I have
                    "name_form": NAME_FORMAT_URI,
                    "nameid_format": NAMEID_FORMAT_PERSISTENT,
                    "entity_categories": ["swamid", "edugain"],
                    "fail_on_missing_requested": False,  # Don't fail on unsatisfied RequiredAttributes
                },
            },
            "subject_data": ("mongodb", "mongodb://eduid_idp:eduid_idp_pw@mongodb.docker/eduid_idp_pysaml2"),
            "session_storage": ("mongodb", "mongodb://eduid_idp:eduid_idp_pw@mongodb.docker/eduid_idp_pysaml2"),
            "name_id_format": [NAMEID_FORMAT_TRANSIENT,
                               NAMEID_FORMAT_PERSISTENT],

            "scope": ["local.eduid.se"],

        },
    },
    "debug": 1,
    "key_file": "/opt/eduid/eduid-idp/etc/idp-public-snakeoil.key",
    "cert_file": "/opt/eduid/eduid-idp/etc/idp-public-snakeoil.pem",
    "metadata": {
        "local": ["/opt/eduid/eduid-idp/etc/dashboard_metadata.xml",
                  ],
    },
    "organization": {
        "display_name": "eduID LOCAL TEST",
        "name": "eduID LOCAL TEST",
        "url": "http://www./",
    },
    "contact_person": [
        {
            "contact_type": "technical",
            "given_name": "eduID",
            "sur_name": "developers",
            "email_address": "eduid-dev@SEGATE.SUNET.SE"
        }, {
            "contact_type": "support",
            "given_name": "Support",
            "email_address": "support@eduid.se"
        },
    ],

    #"crypto_backend": "XMLSecurity",

    #"xmlsec_binary": "/bin/false",  # pysaml2 checks for this
    # This database holds the map between a subjects local identifier and
    # the identifier returned to a SP
    "attribute_map_dir": "/opt/eduid/eduid-idp/etc/attributemaps",
    "logger": {
        "rotating": {
            "filename": "/var/log/eduid/pysaml2.log",
            "maxBytes": 500000,
            "backupCount": 5,
        },
        "loglevel": "debug",
    }
}