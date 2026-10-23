[![Pharo version](https://img.shields.io/badge/Pharo-14-%23aac9ff.svg)](https://github.com/pharo-project/Pharo)

# SoundBank

Wwise-style sound banks for Pharo. A bank maps events to sounds: random, sequence, and layer containers with pitch, volume, and delay randomizers, shared counters for "every nth time", and fallbacks from specific to general events. An engine plays posted events on a SuperCollider server through [Scsynth](https://github.com/Gabriel-Darbord/Scsynth), without ever blocking the poster.

## Pharo Version Policy

This project is developed on Pharo 14, the only version it has been tested on.

## Installation

Load the project into a Pharo image with Metacello (it loads Scsynth too):

```smalltalk
Metacello new
  githubUser: 'Gabriel-Darbord' project: 'SoundBank' commitish: 'main' path: 'src';
  baseline: 'SoundBank';
  load
```

Playing sounds needs SuperCollider installed; see [Scsynth's installation](https://github.com/Gabriel-Darbord/Scsynth#installation).

## Quick Start

```smalltalk
engine := SBEngine default.
engine start.                          "start the audio server and the player process"
engine loadBank: '/path/to/my-bank'.   "a directory: sound files and bank.ston"
engine postNamed: 'door.open'.          "plays the sound mapped to door.open"
engine post: (SBEvent
	subjects: #( 'kitchen-door' 'door' '*' )
	phases: #( 'slammed' 'open' )).
engine stop.
```

## Banks

A bank is a directory of sound files (WAV, AIFF, FLAC, Ogg, or MP3, in any subdirectories) and a `bank.ston` description. A sample is named by its path without extension, such as `bell/c5`.

```
{
	'name' : 'example',
	'sets' : { 'doors' : [ 'kitchen-door', 'front-door' ] },
	'sounds' : { 'creak' : [ 'door/creak-1', 'door/creak-2', 'door/creak-3' ] },
	'events' : {
		'doors.open' : { 'use' : 'creak', 'pitch' : [ -50, 50 ], 'volume' : [ -6, 0 ] },
		'front-door.open' : { 'every' : 10, 'counter' : 'visits', 'then' : 'bell/ding-dong', 'otherwise' : { 'use' : 'creak' } },
		'*.slammed' : { 'layer' : [ 'door/slam', { 'sound' : 'glass/rattle', 'delay' : 120 } ] },
		'cat.open' : nil
	}
}
```

A sound is one of:

| Form | Plays |
|---|---|
| `'a/sample'` | that sample |
| `nil` | nothing, and stops the fallback to later keys |
| `[ ... ]` | one child at random (shorthand for `random`) |
| `{ 'sound' : 'a/sample' }` | a sample, with randomizers |
| `{ 'use' : 'name' }` | a named sound from `sounds`, shared with its other uses |
| `{ 'random' : [ ... ], 'avoidRepeat' : 2 }` | one child at random, by weight, not one of the last 2 played (default 1) |
| `{ 'sequence' : [ ... ] }` | one child per trigger, round-robin |
| `{ 'layer' : [ ... ] }` | all children at once |
| `{ 'every' : 8, 'counter' : 'c', 'then' : ..., 'otherwise' : ... }` | `then` on every 8th trigger of counter `c`, `otherwise` the rest of the time |

Any map also accepts randomizers, each a number or a `[ min, max ]` range: `pitch` in cents, `volume` in decibels, `delay` in milliseconds. A container's randomizers add to its children's. `weight` (default 1) sets how likely a random container picks it.

### Event Lookup

An event has subjects, from most to least specific, and phases, from most to least important. Its keys are `subject.phase`, phase by phase, each subject followed by the sets that contain it; the first key the bank maps wins. So a more important phase beats a more specific subject:

```
SBEvent subjects: #( 'front-door' 'door' '*' ) phases: #( 'slammed' 'open' )
→ front-door.slammed, doors.slammed, door.slammed, *.slammed, front-door.open, doors.open, ...
```

`SBBank>>matchingKeyFor:` answers the key that decides an event's sound; `missingSampleNames` and `unusedSampleNames` check a bank against its files.

## Tools

Python scripts to prepare samples, using only the standard library (and [SoundCraft](https://github.com/storytold/soundcraft)'s CLI where noted):

- `tools/extract_clips.py` cuts a compilation (such as a video's soundtrack) into one clip per sound, from approximate start times.
- `tools/trim_clips.py` cuts the chosen part of each clip, with fades, and never overwrites hand-made files.
- `tools/eq_samples.py` equalizes samples with SoundCraft's 7-band EQ, headless.
- `tools/import_samples.py` copies a bank's samples from their sources into the bank, as peak-normalized FLAC (with SoundCraft).

## Documentation

The class comments of `SBEngine`, `SBBank`, `SBBankReader`, `SBEvent`, and the `SBSoundNode` hierarchy describe the API.
