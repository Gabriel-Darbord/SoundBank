"""Cut a compilation WAV into one WAV per sound, using approximate start times.

Usage: python3 tools/extract_clips.py <compilation.wav> <clips.tsv> <output-directory> [--report]

clips.tsv has one clip per line: start time (m:ss or seconds), name, label; '#' lines are comments.
Start times from video comments are rough, so each one snaps to the nearest sound onset found in
the audio (silence-to-sound transitions). A start written as '=m:ss.ss' is exact and does not
snap, for sounds that follow another one without a gap. A clip runs from its start to the next
clip's start, then near-silence is trimmed from both ends and short fades are applied.

Only the Python standard library is used. Input must be 16-bit PCM WAV (any rate, any channels).
"""

import array
import math
import sys
import wave
from pathlib import Path

WINDOW_SECONDS = 0.01          # envelope resolution
SILENCE_DB = -45.0             # below this (relative to full scale) a window counts as silent
MINIMUM_GAP_SECONDS = 0.04     # silence shorter than this does not separate two sounds
SNAP_SECONDS = 1.5             # how far a listed start may be from the real onset
FADE_SECONDS = 0.005


def read_wave(path):
    with wave.open(str(path), 'rb') as source:
        if source.getsampwidth() != 2:
            raise SystemExit(f'{path}: expected 16-bit PCM, got {8 * source.getsampwidth()}-bit')
        channels = source.getnchannels()
        rate = source.getframerate()
        samples = array.array('h', source.readframes(source.getnframes()))
    if sys.byteorder == 'big':
        samples.byteswap()
    return samples, channels, rate


def envelope(samples, channels, rate):
    """Peak level in dBFS per window."""
    window = int(rate * WINDOW_SECONDS) * channels
    levels = []
    for start in range(0, len(samples), window):
        chunk = samples[start:start + window]
        peak = max((abs(s) for s in chunk), default=0)
        levels.append(20 * math.log10(peak / 32768) if peak else -120.0)
    return levels


def onsets(levels):
    """Window indexes where sound starts after at least MINIMUM_GAP_SECONDS of silence."""
    minimum_gap = int(MINIMUM_GAP_SECONDS / WINDOW_SECONDS)
    found, silent_run = [], minimum_gap
    for index, level in enumerate(levels):
        if level < SILENCE_DB:
            silent_run += 1
        else:
            if silent_run >= minimum_gap:
                found.append(index)
            silent_run = 0
    return found


def parse_time(text):
    minutes, _, seconds = text.rpartition(':')
    return float(minutes or 0) * 60 + float(seconds)


def read_clips(path):
    clips = []
    for line in Path(path).read_text(encoding='utf-8').splitlines():
        if line.strip() and not line.startswith('#'):
            start, name, label = line.split('\t')
            exact = start.startswith('=')
            clips.append((parse_time(start.lstrip('=')), exact, name, label))
    return clips


def snap(clips, onset_seconds, duration):
    """Snap each listed start to the closest unused onset, keeping clips in order. Answer
    (start, listed, name, label, note) tuples."""
    snapped, previous = [], -1.0
    for listed, exact, name, label in clips:
        candidates = [] if exact else [o for o in onset_seconds if o > previous and abs(o - listed) <= SNAP_SECONDS]
        if exact:
            start, note = listed, '  (exact)'
        elif candidates:
            start, note = min(candidates, key=lambda o: abs(o - listed)), ''
        else:
            start, note = max(listed, previous + WINDOW_SECONDS), '  (no onset nearby: kept listed time)'
        start = min(start, duration)
        snapped.append((start, listed, name, label, note))
        previous = start
    return snapped


def trim(samples, channels, rate, first_frame, end_frame):
    """Shrink [first_frame, end_frame) to the part above the silence threshold."""
    threshold = 32768 * 10 ** (SILENCE_DB / 20)

    def loud(frame):
        base = frame * channels
        return any(abs(samples[base + c]) >= threshold for c in range(channels))

    while first_frame < end_frame and not loud(first_frame):
        first_frame += 1
    while end_frame > first_frame and not loud(end_frame - 1):
        end_frame -= 1
    return first_frame, end_frame


def write_clip(path, samples, channels, rate, first_frame, end_frame):
    clip = samples[first_frame * channels:end_frame * channels]
    frames = end_frame - first_frame
    fade = min(int(rate * FADE_SECONDS), frames // 2)
    for i in range(fade):
        gain = i / fade
        for c in range(channels):
            clip[i * channels + c] = int(clip[i * channels + c] * gain)
            clip[(frames - 1 - i) * channels + c] = int(clip[(frames - 1 - i) * channels + c] * gain)
    if sys.byteorder == 'big':
        clip.byteswap()
    with wave.open(str(path), 'wb') as output:
        output.setnchannels(channels)
        output.setsampwidth(2)
        output.setframerate(rate)
        output.writeframes(clip.tobytes())


def main():
    if len(sys.argv) < 4:
        raise SystemExit(__doc__)
    source, manifest, target = Path(sys.argv[1]), sys.argv[2], Path(sys.argv[3])
    report_only = '--report' in sys.argv
    samples, channels, rate = read_wave(source)
    total_frames = len(samples) // channels
    duration = total_frames / rate
    onset_seconds = [index * WINDOW_SECONDS for index in onsets(envelope(samples, channels, rate))]
    snapped = snap(read_clips(manifest), onset_seconds, duration)
    target.mkdir(parents=True, exist_ok=True)
    for index, (start, listed, name, label, note) in enumerate(snapped):
        end = snapped[index + 1][0] if index + 1 < len(snapped) else duration
        first_frame, end_frame = trim(samples, channels, rate, int(start * rate), min(int(end * rate), total_frames))
        length = (end_frame - first_frame) / rate
        print(f'{name:28} listed {listed:7.2f}  start {first_frame / rate:7.2f}  length {length:5.2f}s{note}')
        if not report_only and end_frame > first_frame:
            write_clip(target / f'{name}.wav', samples, channels, rate, first_frame, end_frame)


if __name__ == '__main__':
    main()
