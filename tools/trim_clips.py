"""Cut the chosen part of each selected clip into a short sample.

Usage: python3 tools/trim_clips.py <selection.tsv> [--max SECONDS]

selection.tsv lives next to all/ (the clips from extract_clips.py) and gets selected/ written beside
it. Each line: timestamp, sample name, source clip name, cut, request, and an optional check note;
'#' lines are comments. One clip can give several samples. The cut is 'whole', 'start-end' in
seconds within the clip, or 'manual' for a sample made by hand, which this tool never touches.
A cut can end with '/seconds' to fade out over that long, such as '0-3/0.5' or 'whole/1'.

A sample longer than --max (default 3 s) is cut to that length with a fade-out. Existing files in
selected/ are never overwritten: delete one to have it cut again, or replace it with your own.

Only the Python standard library is used. Clips must be 16-bit PCM WAV.
"""

import array
import sys
import wave
from pathlib import Path

EDGE_FADE_SECONDS = 0.01
CAP_FADE_SECONDS = 0.25


def read_selection(path):
    for line in Path(path).read_text(encoding='utf-8').splitlines():
        if line.strip() and not line.startswith('#'):
            fields = line.split('\t') + ['']
            yield fields[1], fields[2], fields[3], fields[5]


def parse_cut(cut, duration):
    """Answer start, end, and fade-out seconds (None when the cut names none)."""
    cut, _, fade_out = cut.partition('/')
    fade_out = float(fade_out) if fade_out else None
    if cut == 'whole':
        return 0.0, duration, fade_out
    start, end = (float(part) for part in cut.split('-'))
    return start, min(end, duration), fade_out


def fade(samples, channels, frames, fade_in, fade_out):
    for i in range(min(fade_in, frames)):
        for c in range(channels):
            samples[i * channels + c] = int(samples[i * channels + c] * i / fade_in)
    for i in range(min(fade_out, frames)):
        index = (frames - 1 - i) * channels
        for c in range(channels):
            samples[index + c] = int(samples[index + c] * i / fade_out)


def trim(source, target, cut, maximum):
    """Write the cut of source to target and answer its length and whether it was capped."""
    with wave.open(str(source), 'rb') as clip:
        if clip.getsampwidth() != 2:
            raise SystemExit(f'{source}: expected 16-bit PCM')
        channels, rate = clip.getnchannels(), clip.getframerate()
        start, end, fade_out = parse_cut(cut, clip.getnframes() / rate)
        clip.setpos(int(start * rate))
        frames = int((end - start) * rate)
        capped = frames > maximum * rate
        frames = min(frames, int(maximum * rate))
        samples = array.array('h', clip.readframes(frames))
    if sys.byteorder == 'big':
        samples.byteswap()
    if fade_out is None:
        fade_out = CAP_FADE_SECONDS if capped else EDGE_FADE_SECONDS
    fade(samples, channels, frames, int(EDGE_FADE_SECONDS * rate), int(fade_out * rate))
    if sys.byteorder == 'big':
        samples.byteswap()
    with wave.open(str(target), 'wb') as output:
        output.setnchannels(channels)
        output.setsampwidth(2)
        output.setframerate(rate)
        output.writeframes(samples.tobytes())
    return frames / rate, capped


def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    selection = Path(sys.argv[1])
    maximum = float(sys.argv[sys.argv.index('--max') + 1]) if '--max' in sys.argv else 3.0
    clips, selected = selection.parent / 'all', selection.parent / 'selected'
    selected.mkdir(exist_ok=True)
    for name, clip, cut, check in read_selection(selection):
        target = selected / f'{name}.wav'
        if cut == 'manual':
            print(f'{name:22} made by hand{"" if target.exists() else ": not there yet"}')
            continue
        if target.exists():
            print(f'{name:22} kept existing file')
            continue
        length, capped = trim(clips / f'{clip}.wav', target, cut, maximum)
        notes = [note for note in (f'capped at {maximum:g} s' if capped else '', check) if note]
        print(f'{name:22} {cut:10} {length:5.2f}s  {"; ".join(notes)}')


if __name__ == '__main__':
    main()
