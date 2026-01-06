import os
import getpass

def get_user():
    return os.environ.get("SUDO_USER") or getpass.getuser()
