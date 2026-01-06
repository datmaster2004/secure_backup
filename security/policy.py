import yaml
from pathlib import Path

class Policy:
    def __init__(self, path):
        self.path = Path(path)
        if not self.path.exists():
            self.data = {}
            return

        with open(self.path, "r", encoding="utf-8") as f:
            self.data = yaml.safe_load(f) or {}

    def allowed(self, user, cmd):
        """
        RBAC check theo policy.yaml
        """
        users = self.data.get("users", {})
        roles = self.data.get("roles", {})

        # USER KHÔNG TỒN TẠI
        if user not in users:
            return False

        role = users[user]

        # ROLE KHÔNG TỒN TẠI
        if role not in roles:
            return False

        # ADMIN → MỌI LỆNH
        if role == "admin":
            return True

        # ROLE KHÁC → CHECK DANH SÁCH LỆNH
        allowed_cmds = roles[role]
        return cmd in allowed_cmds