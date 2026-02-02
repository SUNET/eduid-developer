#!/usr/bin/env python3
"""List available tokens."""
def main() -> None:
    from hsmkey import SessionPool
    pool = SessionPool(
        module_path="/usr/lib/softhsm/libsofthsm2.so",
        token_label="eduid-hasher",
        user_pin="1234",  # <-- what PIN are you using?
    )
    with pool.session() as session:
        print("Session opened successfully!")
if __name__ == "__main__":
    main()

