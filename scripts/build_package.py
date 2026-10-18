"""Build/verify the Unity package using only Python's standard library."""

import argparse
import gzip
import io
from pathlib import Path
import re
import sys
import tarfile


ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "PanoramaPortalSkybox.unitypackage"


def normalized_bytes(path):
    # Unity assets in this package are text. Normalize Git's Windows checkouts.
    return path.read_bytes().replace(b"\r\n", b"\n")


def build_archive(root=ROOT):
    folder = root / "Assets/PanoramaPortalSkybox"
    if not folder.is_dir():
        raise ValueError("Missing Assets/PanoramaPortalSkybox")
    paths = [folder, *sorted(folder.rglob("*"))]
    assets = {}
    guids = set()
    for path in paths:
        if path.suffix == ".meta":
            if not path.with_suffix("").exists():
                raise ValueError(f"Orphan metadata: {path}")
            continue
        if path.is_symlink():
            raise ValueError(f"Symlinks are not supported: {path}")
        if path.is_file() and path.suffix not in {".shader", ".mat", ".md"}:
            raise ValueError(f"Unsupported asset type (extend builder explicitly): {path}")
        meta = Path(str(path) + ".meta")
        if not meta.is_file():
            raise ValueError(f"Missing metadata: {meta}")
        meta_data = normalized_bytes(meta)
        match = re.search(rb"^guid: ([0-9a-f]{32})$", meta_data, re.MULTILINE)
        if not match:
            raise ValueError(f"Invalid GUID: {meta}")
        guid = match[1].decode("ascii")
        if guid in guids:
            raise ValueError(f"Duplicate GUID: {guid}")
        guids.add(guid)
        is_folder = path.is_dir()
        if is_folder != (b"folderAsset: yes" in meta_data):
            raise ValueError(f"Folder metadata mismatch: {meta}")
        assets[path.relative_to(root).as_posix()] = (
            guid, meta_data, None if is_folder else normalized_bytes(path)
        )

    shader_path = "Assets/PanoramaPortalSkybox/PanoramaPortalSky.shader"
    material_path = "Assets/PanoramaPortalSkybox/PanoramaPortalSkybox.mat"
    for required in [shader_path, material_path, "Assets/PanoramaPortalSkybox/README.md"]:
        if required not in assets:
            raise ValueError(f"Missing required asset: {required}")
    shader_guid = assets[shader_path][0].encode("ascii")
    material = assets[material_path][2]
    reference = re.search(rb"m_Shader: \{fileID: 4800000, guid: ([0-9a-f]{32}), type: 3\}", material)
    if not reference or reference[1] != shader_guid:
        raise ValueError("Material must reference the bundled shader GUID")

    output = io.BytesIO()
    with tarfile.open(fileobj=output, mode="w", format=tarfile.USTAR_FORMAT) as archive:
        for pathname, (guid, meta, asset) in sorted(assets.items()):
            entries = {"asset.meta": meta, "pathname": pathname.encode("utf-8")}
            if asset is not None:
                entries["asset"] = asset
            for name, data in sorted(entries.items()):
                info = tarfile.TarInfo(f"{guid}/{name}")
                info.size = len(data)
                info.mode = 0o644
                # TarInfo defaults to zero timestamp, uid and gid.
                archive.addfile(info, io.BytesIO(data))
    return output.getvalue()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Verify without modifying files")
    args = parser.parse_args()
    try:
        expected = build_archive()
        if args.check:
            if gzip.decompress(PACKAGE.read_bytes()) != expected:
                raise ValueError("Package is stale. Run: python scripts/build_package.py")
            print("OK: package matches sources; metadata and shader reference are valid.")
        else:
            output = io.BytesIO()
            with gzip.GzipFile(fileobj=output, mode="wb", filename="", mtime=0) as stream:
                stream.write(expected)
            PACKAGE.write_bytes(output.getvalue())
            print(f"Built {PACKAGE.name} ({PACKAGE.stat().st_size} bytes)")
    except (OSError, ValueError, EOFError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
