class Snapshot:
    def __init__(self, sid, label, root, prev_root):
        self.id = sid
        self.label = label
        self.root = root
        self.prev_root = prev_root
