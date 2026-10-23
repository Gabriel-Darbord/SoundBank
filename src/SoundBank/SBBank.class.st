"
I am a set of sounds loaded on a SuperCollider server, plus a mapping from event keys to sound nodes.

A bank lives in a directory: sound files (WAV, AIFF, FLAC, Ogg, or MP3, in any subdirectories) and a bank.ston description. A sample is named by its path without extension, such as 'bell/c5'. See SBBankReader for the description format.

Sets let one entry cover many subjects: with a set 'edit' containing 'method_rewrite', an event about method_rewrite also looks up 'edit.<phase>', right after 'method_rewrite.<phase>'.

Events that no key matches play nothing.
"
Class {
	#name : 'SBBank',
	#superclass : 'Object',
	#instVars : [
		'name',
		'events',
		'sounds',
		'setsBySubject'
	],
	#category : 'SoundBank-Banks',
	#package : 'SoundBank',
	#tag : 'Banks'
}

{ #category : 'instance creation' }
SBBank class >> empty [

	^ self named: 'empty' sounds: Dictionary new events: Dictionary new
]

{ #category : 'instance creation' }
SBBank class >> fromDirectory: aDirectory server: anScsynthServer [
	"Read the bank in aDirectory and load its sound files on anScsynthServer."

	^ SBBankReader new readDirectory: aDirectory asFileReference server: anScsynthServer
]

{ #category : 'instance creation' }
SBBank class >> named: aName sounds: aDictionary events: someEvents [
	"aDictionary maps sample names to sounds loaded on a server."

	^ self
		  named: aName
		  sounds: aDictionary
		  events: someEvents
		  sets: Dictionary new
]

{ #category : 'instance creation' }
SBBank class >> named: aName sounds: aDictionary events: someEvents sets: someSets [
	"someSets maps a set name to the subjects it contains, such as 'edit' -> #( 'method_compile' 'method_rewrite' )."

	^ self new
		  setName: aName
		  sounds: aDictionary
		  events: someEvents
		  sets: someSets;
		  yourself
]

{ #category : 'accessing' }
SBBank >> eventKeys [

	^ events keys sorted
]

{ #category : 'playing' }
SBBank >> free [
	"Release my sounds on their server."

	sounds do: [ :sound | sound free ]
]

{ #category : 'accessing' }
SBBank >> keysFor: anEvent [

	^ anEvent keysExpandingSubjectsWith: setsBySubject
]

{ #category : 'accessing' }
SBBank >> matchingKeyFor: anEvent [
	"The key that decides anEvent's sound, or nil when none of its keys is mapped."

	^ (self keysFor: anEvent) detect: [ :key | events includesKey: key ] ifNone: [ nil ]
]

{ #category : 'validating' }
SBBank >> missingSampleNames [

	| missing |
	missing := Set new.
	events do: [ :node | node sampleNamesDo: [ :sampleName | (sounds includesKey: sampleName) ifFalse: [ missing add: sampleName ] ] ].
	^ missing sorted
]

{ #category : 'accessing' }
SBBank >> name [

	^ name
]

{ #category : 'accessing' }
SBBank >> nodeFor: anEvent [

	^ (self matchingKeyFor: anEvent) ifNil: [ SBSilence new ] ifNotNil: [ :key | events at: key ]
]

{ #category : 'playing' }
SBBank >> play: aPlayback [

	(self soundNamed: aPlayback sampleName)
		playRate: aPlayback pitchRatio
		amplitude: aPlayback gain
		delay: aPlayback delayMilliseconds / 1000
]

{ #category : 'playing' }
SBBank >> playbacksFor: anEvent with: aRandom [

	^ (self nodeFor: anEvent) playbacksWith: aRandom
]

{ #category : 'printing' }
SBBank >> printOn: aStream [

	super printOn: aStream.
	aStream
		nextPut: $(;
		nextPutAll: name;
		nextPut: $)
]

{ #category : 'accessing' }
SBBank >> sampleNames [

	^ sounds keys sorted
]

{ #category : 'initialization' }
SBBank >> setName: aName sounds: aDictionary events: someEvents sets: someSets [
	"Index the sets by subject; a subject in several sets lists them in name order."

	name := aName.
	sounds := aDictionary.
	events := someEvents.
	setsBySubject := Dictionary new.
	someSets keys sorted do: [ :setName |
		(someSets at: setName) do: [ :subject | (setsBySubject at: subject ifAbsentPut: [ OrderedCollection new ]) add: setName ] ]
]

{ #category : 'accessing' }
SBBank >> setsContaining: aSubject [

	^ (setsBySubject at: aSubject ifAbsent: [ #(  ) ]) asArray
]

{ #category : 'accessing' }
SBBank >> soundNamed: aSampleName [

	^ sounds at: aSampleName ifAbsent: [ SBBankError signal: 'Bank ' , name , ' has no sample named ' , aSampleName ]
]

{ #category : 'validating' }
SBBank >> unusedSampleNames [
	"Samples that no event can play."

	| used |
	used := Set new.
	events do: [ :node | node sampleNamesDo: [ :sampleName | used add: sampleName ] ].
	^ (sounds keys reject: [ :sampleName | used includes: sampleName ]) sorted
]

{ #category : 'validating' }
SBBank >> validate [

	self missingSampleNames ifNotEmpty: [ :missing |
		SBBankError signal: 'Bank ' , name , ' references missing samples: ' , (missing joinUsing: ', ') ]
]
