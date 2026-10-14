#!/bin/bash
# Host-only replay: provide the user reference as argument 2 when bootstrapping.
set -euo pipefail
cd "$(dirname "$0")/.."
replay_dir="${1:-$PWD/.build-evidence/recognition-fix}"
reference_image="${2:-$replay_dir/user-floor1.png}"
mkdir -p "$replay_dir"
python3 - "$replay_dir" "$reference_image" <<'PY'
import hashlib, json, pathlib, shutil, sys, urllib.request
root=pathlib.Path(sys.argv[1]).resolve()
reference=pathlib.Path(sys.argv[2]).resolve()
if not reference.is_file():
    raise SystemExit('Missing user reference. Usage: scripts/test-recognition-replay.sh [fixture-directory] [reference-image.png]')
target=root/'user-floor1.png'
if reference!=target: shutil.copyfile(reference,target)
commit='b81965ba78918d8d6effb0e5006dc3c9b2e617c9'
fixtures=[
 ('floor1-template01-normal-001','94b97a1684c07dfe2140692171cc0857e4ea277a3e144c91c09b2b1159b8cef1'),
 ('floor2-template03-normal-001','e15e88b443165fc0b4a09dd1549bca686e3a6efdfc7b41d2ef84b5cf1523638e'),
 ('floor3-template01-op7-001','fde70b755c4c4a588f36a65bcc914840ad16645dd4dfd7b0dd48a1f513d5cc2c'),
 ('floor4-template03-normal-001','983f2b5ae62f37bc38718f4ea8c27d377e9e415436e1b8c4f62390eb87128975'),
 ('floor5-template01-normal-001','c77647bda74a59983bf3e0d9a04b615043541f0cb5dce824db6f3f9d9875c4ea')]
manifest=[{'file':target.name,'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'source':'user-provided reference'}]
for name,digest in fixtures:
    url=f'https://raw.githubusercontent.com/ega0123/hlsh-helper/{commit}/android/recognition-native/src/androidTest/assets/fixtures/three_frame/{name}/frame_1.png'
    path=root/(name+'.png')
    if not path.exists():
        with urllib.request.urlopen(url,timeout=60) as response: data=response.read()
        if hashlib.sha256(data).hexdigest()!=digest: raise SystemExit('Downloaded fixture checksum mismatch: '+name)
        path.write_bytes(data)
    if hashlib.sha256(path.read_bytes()).hexdigest()!=digest: raise SystemExit('Fixture checksum mismatch: '+name)
    manifest.append({'file':path.name,'sha256':digest,'sourceURL':url})
(root/'fixtures.json').write_text(json.dumps(manifest,indent=2)+'\n')
PY
replay_dir="$(cd "$replay_dir" && pwd)"
TREESEA_REPLAY_DIR="$replay_dir" TREESEA_REPLAY_OUTPUT="$replay_dir/replay-final.json" \
  scripts/test-support.sh 2>&1 | tee "$replay_dir/support.log"
