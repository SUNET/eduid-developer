BASE='https://eduid.se/SAML/'


MAP = {
    "identifier": "urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified",
    'fro': {
        BASE+'idp-credentials-used': 'eduidIdPCredentialsUsed',
    },
    'to': {
        'eduidIdPCredentialsUsed': BASE+'idp-credentials-used',
    }
}
