from collections import OrderedDict

def build_manifest(file_chunks: dict):
    manifest = OrderedDict()
    for path in sorted(file_chunks.keys()):
        manifest[path] = file_chunks[path]
    return manifest
