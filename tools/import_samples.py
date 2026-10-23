"""Copy a bank's samples from where they are kept into the bank, peak-normalized.

Usage: python3 tools/import_samples.py <soundcraft-cli> <manifest.tsv> <source-root> <bank-directory>

Each manifest line: sample name (a path without extension in the bank, such as 'garand/shot-3'),
then the source file relative to source-root; '#' lines are comments. Each
sample is converted with SoundCraft to 16-bit FLAC normalized to -0.1 dBFS peak, so the bank's
volume settings alone set relative loudness. FLAC is lossless and about 40% smaller than WAV;
scsynth reads it directly. (SoundCraft cannot write MP3.)

A sample is converted again only when its source is newer. Missing sources are reported and
skipped, so a bank can list samples that are still being made.
"""

import subprocess
import sys
from pathlib import Path


def read_manifest(path):
    for line in Path(path).read_text(encoding='utf-8').splitlines():
        if line.strip() and not line.startswith('#'):
            name, source = line.split('\t')
            yield name, source


def main():
    if len(sys.argv) != 5:
        raise SystemExit(__doc__)
    soundcraft, manifest, root, bank = sys.argv[1], Path(sys.argv[2]), Path(sys.argv[3]), Path(sys.argv[4])
    converted = skipped = missing = 0
    for name, source in read_manifest(manifest):
        source_file = root / source
        target = bank / f'{name}.flac'
        if not source_file.exists():
            print(f'missing   {name:34} {source}')
            missing += 1
            continue
        if target.exists() and target.stat().st_mtime >= source_file.stat().st_mtime:
            skipped += 1
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        result = subprocess.run([soundcraft, 'convert', str(source_file), str(target), '--bit-depth', '16', '--normalize'],
                                capture_output=True, text=True)
        if result.returncode != 0:
            raise SystemExit(f'{source_file}: soundcraft failed\n{result.stdout}{result.stderr}')
        converted += 1
    print(f'{converted} converted, {skipped} up to date, {missing} missing')


if __name__ == '__main__':
    main()
