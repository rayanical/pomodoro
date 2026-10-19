#!/bin/zsh
set -eu
cd "${0:A:h:h}"
iconset="$PWD/build/Pomodoro.iconset"
mkdir -p "$iconset"
for size in 16 32 128 256 512; do
    sips -z "$size" "$size" Assets/Pomodoro.png --out "$iconset/icon_${size}x${size}.png" >/dev/null
    double=$((size * 2))
    sips -z "$double" "$double" Assets/Pomodoro.png --out "$iconset/icon_${size}x${size}@2x.png" >/dev/null
done
python3 - <<'PY'
from pathlib import Path
import struct

# ICNS stores the PNG representations in typed chunks without changing pixels.
iconset = Path('build/Pomodoro.iconset')
representations = {
    'icp4': 'icon_16x16.png', 'icp5': 'icon_32x32.png',
    'icp6': 'icon_32x32@2x.png', 'ic07': 'icon_128x128.png',
    'ic08': 'icon_256x256.png', 'ic09': 'icon_512x512.png',
    'ic10': 'icon_512x512@2x.png', 'ic11': 'icon_16x16@2x.png',
    'ic12': 'icon_32x32@2x.png', 'ic13': 'icon_128x128@2x.png',
    'ic14': 'icon_256x256@2x.png',
}
chunks = []
for kind, filename in representations.items():
    data = (iconset / filename).read_bytes()
    chunks.append(kind.encode('ascii') + struct.pack('>I', len(data) + 8) + data)
payload = b''.join(chunks)
Path('Assets/Pomodoro.icns').write_bytes(b'icns' + struct.pack('>I', len(payload) + 8) + payload)
PY
