from utils.hashing import sha256

def merkle_root(leaves):
    if not leaves:
        return sha256(b"")

    level = leaves[:]
    while len(level) > 1:
        if len(level) % 2 == 1:
            level.append(level[-1])
        next_level = []
        for i in range(0, len(level), 2):
            combined = (level[i] + level[i+1]).encode()
            next_level.append(sha256(combined))
        level = next_level
    return level[0]
