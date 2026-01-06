from config import CHUNK_SIZE
from utils.hashing import sha256

def chunk_file(path):
    with open(path, "rb") as f:
        while True:
            data = f.read(CHUNK_SIZE)
            if not data:
                break
            yield data, sha256(data)
