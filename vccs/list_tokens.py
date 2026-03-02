#!/usr/bin/env python3
"""List available tokens."""

from hsmkey import SessionPool

def main() -> None:
    pool = SessionPool(
        module_path="/usr/lib/softhsm/libsofthsm2.so",
        token_label="eduid-hasher",
        user_pin="1234",
    )
    with pool.session() as session:
        print("Session opened successfully!")
        print(f"token label: {session.token}")
if __name__ == "__main__":
    main()

