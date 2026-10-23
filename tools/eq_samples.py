"""Equalize samples with SoundCraft's 7-band EQ, headless.

Usage: python3 tools/eq_samples.py <soundcraft-cli> <output-directory> '<EQ params JSON>' <sample.wav>...

Example, attenuating the sharp highs of gunshots without removing them:
  python3 tools/eq_samples.py soundcraft/target/release/soundcraft-cli eq \\
      '{"high_shelf_freq": 3000, "high_shelf_gain": -12}' selected/shot-*.wav

Each sample is imported into an empty SoundCraft session, the eq_7band plugin is inserted with the
given parameters (see `soundcraft-cli run ... --cmd 'session.inspect={"detail":"full"}'` for their
names), and the mix is bounced as 16-bit WAV at the session rate (48 kHz) into the output directory
under the same name. Existing output files are never overwritten.

Note: the shelf attenuates sharp transients less than steady sounds (about 5 dB at the attack of
a shot for a -9 dB shelf, against 8 dB on steady noise), so ask for more than you want to hear.
"""

import json
import os
import subprocess
import sys
from pathlib import Path


def equalize(soundcraft, source, target, params):
    track = source.stem
    commands = [
        f'file.import_audio={json.dumps({"path": str(source.resolve())})}',
        f'mix.insert={json.dumps({"track": track, "plugin": "eq_7band", "params": params})}',
        f'file.bounce_mix={json.dumps({"path": str(target.resolve()), "bit_depth": 16, "dither": False})}',
    ]
    arguments = [soundcraft, 'run']
    for command in commands:
        arguments += ['--cmd', command]
    result = subprocess.run(arguments, capture_output=True, text=True,
                            env={**os.environ, 'SOUNDCRAFT_NO_PREFS': '1'})
    if result.returncode != 0 or not target.exists():
        raise SystemExit(f'{source}: soundcraft failed\n{result.stdout}{result.stderr}')
    bounce = next(line for line in result.stdout.splitlines() if line.startswith('file.bounce_mix:'))
    return json.loads(bounce.partition(':')[2])


def main():
    if len(sys.argv) < 5:
        raise SystemExit(__doc__)
    soundcraft, output, params = sys.argv[1], Path(sys.argv[2]), json.loads(sys.argv[3])
    output.mkdir(parents=True, exist_ok=True)
    for source in map(Path, sys.argv[4:]):
        target = output / source.name
        if target.exists():
            print(f'{source.stem:12} kept existing file')
            continue
        report = equalize(soundcraft, source, target, params)
        print(f'{source.stem:12} {report["seconds"]:5.2f}s  peak {report["peak_db"]:6.1f} dB')


if __name__ == '__main__':
    main()
