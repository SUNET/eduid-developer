#!/usr/bin/env python3
"""List HMAC keys in a SoftHSM2 token using hsmkey."""
from hsmkey import SessionPool
from pkcs11 import Attribute, ObjectClass

# Configure for your token
MODULE_PATH = "/usr/lib/softhsm/libsofthsm2.so"
TOKEN_LABEL = "eduid-hasher"
USER_PIN = "1234"


def main() -> None:
    pool = SessionPool(
        module_path=MODULE_PATH,
        token_label=TOKEN_LABEL,
        user_pin=USER_PIN,
    )
    with pool.session() as session:
        print("=== Secret Keys ===\n")

        for obj in session.get_objects({Attribute.CLASS: ObjectClass.SECRET_KEY}):
            # Fetch attributes explicitly - safer than direct property access
            try:
                attrs = obj.get_attributes(
                    [
                        Attribute.LABEL,
                        Attribute.ID,
                        Attribute.KEY_TYPE,
                    ]
                )

                label = attrs.get(Attribute.LABEL, "")
                key_id = attrs.get(Attribute.ID, b"")
                key_type = attrs.get(Attribute.KEY_TYPE)

                # Convert key_id bytes to int
                key_handle = int.from_bytes(key_id, byteorder="big") if key_id else None

                print(f"Label:      {label}")
                print(f"ID (bytes): {key_id.hex() if key_id else 'None'}")
                print(f"ID (int):   {key_handle}")
                print(f"Key Type:   {key_type}")
                print()
            except Exception as e:
                print(f"Error reading key: {e}\n")


if __name__ == "__main__":
    main()
