"
I am one resolved sound to play: which sample, and the pitch, volume, and delay drawn for this particular trigger.

A sample renders me into PCM bytes.
"
Class {
	#name : 'SBPlayback',
	#superclass : 'Object',
	#instVars : [
		'sampleName',
		'pitchCents',
		'volumeDecibels',
		'delayMilliseconds'
	],
	#category : 'SoundBank-Model',
	#package : 'SoundBank',
	#tag : 'Model'
}

{ #category : 'instance creation' }
SBPlayback class >> sampleName: aName pitchCents: cents volumeDecibels: decibels delayMilliseconds: milliseconds [

	^ self new
		  setSampleName: aName
		  pitchCents: cents
		  volumeDecibels: decibels
		  delayMilliseconds: milliseconds;
		  yourself
]

{ #category : 'accessing' }
SBPlayback >> delayMilliseconds [

	^ delayMilliseconds
]

{ #category : 'accessing' }
SBPlayback >> gain [

	^ 10 raisedTo: volumeDecibels / 20.0
]

{ #category : 'accessing' }
SBPlayback >> pitchCents [

	^ pitchCents
]

{ #category : 'accessing' }
SBPlayback >> pitchRatio [
	"1200 cents per octave."

	^ 2 raisedTo: pitchCents / 1200.0
]

{ #category : 'printing' }
SBPlayback >> printOn: aStream [

	super printOn: aStream.
	aStream
		nextPut: $(;
		nextPutAll: sampleName;
		nextPutAll: ' pitch: ';
		print: pitchCents rounded;
		nextPutAll: ' volume: ';
		print: volumeDecibels rounded;
		nextPutAll: ' delay: ';
		print: delayMilliseconds rounded;
		nextPut: $)
]

{ #category : 'accessing' }
SBPlayback >> sampleName [

	^ sampleName
]

{ #category : 'initialization' }
SBPlayback >> setSampleName: aName pitchCents: cents volumeDecibels: decibels delayMilliseconds: milliseconds [

	sampleName := aName.
	pitchCents := cents.
	volumeDecibels := decibels.
	delayMilliseconds := milliseconds max: 0
]

{ #category : 'accessing' }
SBPlayback >> volumeDecibels [

	^ volumeDecibels
]
