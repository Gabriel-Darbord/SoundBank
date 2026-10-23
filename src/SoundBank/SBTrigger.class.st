"
I carry one trigger through a tree of sound nodes. Each node draws its randomizers and passes a nested trigger to its children, so offsets accumulate like Wwise properties: a container's pitch, volume, and delay add to its children's.

Sounds add playbacks to me; all nested triggers share the same playback list and random generator.
"
Class {
	#name : 'SBTrigger',
	#superclass : 'Object',
	#instVars : [
		'random',
		'pitchCents',
		'volumeDecibels',
		'delayMilliseconds',
		'playbacks'
	],
	#category : 'SoundBank-Model',
	#package : 'SoundBank',
	#tag : 'Model'
}

{ #category : 'instance creation' }
SBTrigger class >> random: aRandom [

	^ self new
		  setRandom: aRandom;
		  yourself
]

{ #category : 'triggering' }
SBTrigger >> pickFrom: someNodes [
	"A random node, each as likely as its weight."

	| point |
	point := random next * (someNodes inject: 0 into: [ :sum :node | sum + node weight ]).
	someNodes do: [ :node |
			point := point - node weight.
			point < 0 ifTrue: [ ^ node ] ].
	^ someNodes last
]

{ #category : 'triggering' }
SBTrigger >> playSampleNamed: aName [

	playbacks add: (SBPlayback
			 sampleName: aName
			 pitchCents: pitchCents
			 volumeDecibels: volumeDecibels
			 delayMilliseconds: delayMilliseconds)
]

{ #category : 'accessing' }
SBTrigger >> playbacks [

	^ playbacks
]

{ #category : 'initialization' }
SBTrigger >> setRandom: aRandom [

	random := aRandom.
	pitchCents := 0.
	volumeDecibels := 0.
	delayMilliseconds := 0.
	playbacks := OrderedCollection new
]

{ #category : 'initialization' }
SBTrigger >> shiftPitchCents: cents volumeDecibels: decibels delayMilliseconds: milliseconds [

	pitchCents := pitchCents + cents.
	volumeDecibels := volumeDecibels + decibels.
	delayMilliseconds := delayMilliseconds + milliseconds
]

{ #category : 'triggering' }
SBTrigger >> varyBy: aNode [
	"Answer a nested trigger with aNode's randomizers drawn and added to my offsets. It shares my random generator and playback list."

	^ self copy
		  shiftPitchCents: (aNode pitch valueFrom: random)
		  volumeDecibels: (aNode volume valueFrom: random)
		  delayMilliseconds: (aNode delay valueFrom: random);
		  yourself
]
