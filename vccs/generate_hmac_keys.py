#!/usr/bin/env python3
"""Generate HMAC keys in the HSM for testing.

HMAC keys are symmetric keys that must be generated directly in the HSM.
"""

from __future__ import annotations

import os

import pkcs11
from pkcs11 import Attribute, KeyType, Mechanism, ObjectClass


# Configuration
HSM_MODULE = os.environ.get("HSM_MODULE", "/usr/lib/softhsm/libsofthsm2.so")
TOKEN_LABEL = os.environ.get("HSM_TOKEN_LABEL", "eduid-hasher")
PIN = os.environ.get("HSM_PIN", "1234")


def generate_hmac_key(
    session: pkcs11.Session,
    key_id: bytes,
    label: str,
    key_length: int = 32,
) -> None:
    """Generate an HMAC key in the HSM.

    Args:
        session: PKCS#11 session
        key_id: Key ID (CKA_ID)
        label: Key label (CKA_LABEL)
        key_length: Key length in bytes (default 32 = 256 bits)
    """
    # Check if key already exists
    try:
        existing = session.get_key(
            key_type=KeyType.GENERIC_SECRET,
            object_class=ObjectClass.SECRET_KEY,
            label=label,
        )
        print(f"  Key '{label}' already exists, skipping...")
        return
    except pkcs11.NoSuchKey:
        pass

    # Generate the secret key
    template = {
        Attribute.CLASS: ObjectClass.SECRET_KEY,
        Attribute.KEY_TYPE: KeyType.GENERIC_SECRET,
        Attribute.TOKEN: True,
        Attribute.PRIVATE: True,
        Attribute.SENSITIVE: True,
        Attribute.EXTRACTABLE: False,
        Attribute.SIGN: True,
        Attribute.VERIFY: True,
        Attribute.ID: key_id,
        Attribute.LABEL: label,
        Attribute.VALUE_LEN: key_length,
    }

    session.generate_key(
        KeyType.GENERIC_SECRET,
        key_length * 8,  # length in bits
        template=template,
    )
    print(f"  Generated '{label}' ({key_length * 8}-bit) successfully")


def main() -> None:
    """Generate HMAC keys in the HSM."""
    print(f"Loading PKCS#11 library: {HSM_MODULE}")
    lib = pkcs11.lib(HSM_MODULE)

    print(f"Opening token: {TOKEN_LABEL}")
    token = lib.get_token(token_label=TOKEN_LABEL)

    with token.open(rw=True, user_pin=PIN) as session:
        # Generate HMAC-SHA1 key (160 bits = 20 bytes recommended)
        print("Generating HMAC-SHA1 key...")
        generate_hmac_key(
            session,
            key_id=bytes([0x20]),
            label="hmac-sha1",
            key_length=20,
        )

        # Generate HMAC-SHA256 key (256 bits = 32 bytes recommended)
        print("Generating HMAC-SHA256 key...")
        generate_hmac_key(
            session,
            key_id=bytes([0x21]),
            label="hmac-sha256",
            key_length=32,
        )

        # Generate HMAC-SHA384 key (384 bits = 48 bytes recommended)
        #print("Generating HMAC-SHA384 key...")
        #generate_hmac_key(
        #    session,
        #    key_id=bytes([0x22]),
        #    label="hmac-sha384",
        #    key_length=48,
        #)

        # Generate HMAC-SHA512 key (512 bits = 64 bytes recommended)
        #print("Generating HMAC-SHA512 key...")
        #generate_hmac_key(
        #    session,
        #    key_id=bytes([0x23]),
        #    label="hmac-sha512",
        #    key_length=64,
        #)

    print("HMAC key generation complete")


if __name__ == "__main__":
    main()

