"
I read a bank directory: every sound file below it (WAV, AIFF, FLAC, Ogg, or MP3), loaded on a server, and its bank.ston description.

The description is a STON map:
	{
		'name' : 'example',
		'sets' : { 'edit' : [ 'method_rewrite', 'class_slot_add' ] },
		'sounds' : { 'shot' : [ 'garand/shot-1', 'garand/shot-2' ] },
		'events' : {
			'edit.start' : { 'every' : 8, 'counter' : 'magazine', 'then' : 'garand/ping', 'otherwise' : { 'use' : 'shot' } },
			'tests.success' : { 'layer' : [ 'bell/c5', { 'sound' : 'bell/e5', 'delay' : 80 } ] },
			'*.error' : 'low/b2',
			'tool_call.success' : nil
		}
	}

'sets' name groups of event subjects (see SBBank); 'sounds' name sounds that events can share; 'events' map event keys to sounds.

A sound is one of:
	'a/sample'                                 plays that sample
	nil                                        plays nothing, and stops the fallback to later keys
	[ ... ]                                    shorthand for a random container
	{ 'sound' : 'a/sample' }                   a sample with randomizers
	{ 'use' : 'name' }                         a named sound from 'sounds', shared with its other uses
	{ 'random' : [ ... ], 'avoidRepeat' : 2 }  one child at random, by weight, avoiding the last 2 played (default 1)
	{ 'sequence' : [ ... ] }                   one child per trigger, round-robin
	{ 'layer' : [ ... ] }                      all children at once
	{ 'every' : 8, 'counter' : 'c', 'then' : ..., 'otherwise' : ... }
	                                           'then' on every 8th trigger of counter c, 'otherwise' the rest of the time

Any map also accepts randomizers, each a number or a [ min, max ] range: 'pitch' in cents, 'volume' in decibels, 'delay' in milliseconds. A container's randomizers add to its children's. 'weight' (default 1) sets how likely a random container picks it.
"
Class {
	#name : 'SBBankReader',
	#superclass : 'Object',
	#instVars : [
		'definitions',
		'namedNodes',
		'resolving',
		'counters'
	],
	#category : 'SoundBank-Banks',
	#package : 'SoundBank',
	#tag : 'Banks'
}

{ #category : 'reading - sounds' }
SBBankReader >> checkKeysOf: aDictionary [

	(aDictionary keys reject: [ :key | self knownKeys includes: key ]) ifNotEmpty: [ :unknown |
		SBBankError signal: 'Unknown sound keys: ' , (unknown joinUsing: ', ') ]
]

{ #category : 'reading - sounds' }
SBBankReader >> counterNamed: aNameOrNil [
	"Cycles naming the same counter count together; a cycle without a counter name counts alone."

	aNameOrNil ifNil: [ ^ SBCounter new ].
	^ counters at: aNameOrNil ifAbsentPut: [ SBCounter new ]
]

{ #category : 'initialization' }
SBBankReader >> defineSounds: aDictionary [
	"Named sounds, built when first used, so they may refer to each other in any order."

	definitions := aDictionary
]

{ #category : 'initialization' }
SBBankReader >> initialize [

	super initialize.
	definitions := Dictionary new.
	namedNodes := Dictionary new.
	resolving := Set new.
	counters := Dictionary new
]

{ #category : 'reading - sounds' }
SBBankReader >> knownKeys [

	^ #( 'sound' 'use' 'random' 'sequence' 'layer' 'every' 'counter' 'then' 'otherwise' 'avoidRepeat' 'pitch' 'volume' 'delay'
	     'weight' )
]

{ #category : 'reading' }
SBBankReader >> loadSoundsIn: aDirectory server: anScsynthServer [

	^ (self soundFilesIn: aDirectory) inject: Dictionary new into: [ :sounds :file |
			  sounds at: (self sampleNameOf: file in: aDirectory) put: (anScsynthServer loadSound: file).
			  sounds ]
]

{ #category : 'reading - sounds' }
SBBankReader >> namedNode: aName [
	"Every use of a named sound shares one node, and so its state (recently played children, sequence position)."

	^ namedNodes at: aName ifAbsent: [
			  | node |
			  (resolving includes: aName) ifTrue: [ SBBankError signal: 'The sound ' , aName , ' uses itself' ].
			  resolving add: aName.
			  node := self readNode: (definitions at: aName ifAbsent: [ SBBankError signal: 'No sound named ' , aName ]).
			  resolving remove: aName.
			  namedNodes at: aName put: node ]
]

{ #category : 'reading - sounds' }
SBBankReader >> readCycle: aDictionary period: aPeriod [

	(aPeriod isInteger and: [ aPeriod > 0 ]) ifFalse: [
		SBBankError signal: 'every needs a positive integer, not ' , aPeriod printString ].
	^ SBCycleContainer
		  counter: (self counterNamed: (aDictionary at: 'counter' ifAbsent: [ nil ]))
		  period: aPeriod
		  special: (self readNode: (aDictionary at: 'then' ifAbsent: [ SBBankError signal: 'every needs a then sound' ]))
		  regular: (self readNode: (aDictionary at: 'otherwise' ifAbsent: [ nil ]))
]

{ #category : 'reading' }
SBBankReader >> readDescriptionIn: aDirectory [

	| file |
	file := aDirectory / 'bank.ston'.
	file exists ifFalse: [ SBBankError signal: 'No bank.ston in ' , aDirectory fullName ].
	^ STON fromString: file contents
]

{ #category : 'reading' }
SBBankReader >> readDirectory: aDirectory server: anScsynthServer [
	"Read the description first, so a malformed bank loads nothing; free the sounds again if they do not match it."

	| description events bank |
	description := self readDescriptionIn: aDirectory.
	self defineSounds: (description at: 'sounds' ifAbsent: [ Dictionary new ]).
	events := self readEvents: (description at: 'events' ifAbsent: [ Dictionary new ]).
	bank := SBBank
		        named: (description at: 'name' ifAbsent: [ aDirectory basename ])
		        sounds: (self loadSoundsIn: aDirectory server: anScsynthServer)
		        events: events
		        sets: (self readSets: (description at: 'sets' ifAbsent: [ Dictionary new ])).
	[ bank validate ] ifCurtailed: [ bank free ].
	^ bank
]

{ #category : 'reading' }
SBBankReader >> readEvents: aDictionary [

	^ aDictionary associations inject: Dictionary new into: [ :events :each |
			  events at: each key put: (self readNode: each value).
			  events ]
]

{ #category : 'reading - sounds' }
SBBankReader >> readNode: aDescription [
	"Bank descriptions are external input, so this boundary dispatches on the STON value's kind."

	aDescription ifNil: [ ^ SBSilence new ].
	aDescription isString ifTrue: [ ^ SBSound sampleName: aDescription ].
	aDescription isArray ifTrue: [ ^ SBRandomContainer withAll: (self readNodes: aDescription) ].
	aDescription isDictionary ifTrue: [ ^ self readNodeMap: aDescription ].
	SBBankError signal: 'Cannot read a sound from ' , aDescription printString
]

{ #category : 'reading - sounds' }
SBBankReader >> readNodeMap: aDictionary [

	| node |
	self checkKeysOf: aDictionary.
	node := self readStructureOf: aDictionary.
	aDictionary at: 'pitch' ifPresent: [ :range | node pitch: (self readRange: range) ].
	aDictionary at: 'volume' ifPresent: [ :range | node volume: (self readRange: range) ].
	aDictionary at: 'delay' ifPresent: [ :range | node delay: (self readRange: range) ].
	aDictionary at: 'weight' ifPresent: [ :weight | node weight: weight ].
	^ node
]

{ #category : 'reading - sounds' }
SBBankReader >> readNodes: someDescriptions [

	^ someDescriptions collect: [ :each | self readNode: each ]
]

{ #category : 'reading - sounds' }
SBBankReader >> readRange: aDescription [

	aDescription isNumber ifTrue: [ ^ SBRange fixed: aDescription ].
	(aDescription isArray and: [ aDescription size = 2 ]) ifTrue: [ ^ SBRange from: aDescription first to: aDescription last ].
	SBBankError signal: 'A randomizer is a number or a [ min, max ] pair, not ' , aDescription printString
]

{ #category : 'reading' }
SBBankReader >> readSets: aDictionary [

	aDictionary keysAndValuesDo: [ :setName :subjects |
			(subjects isArray and: [ subjects allSatisfy: [ :subject | subject isString ] ]) ifFalse: [
				SBBankError signal: 'The set ' , setName , ' must be a list of names' ] ].
	^ aDictionary
]

{ #category : 'reading - sounds' }
SBBankReader >> readStructureOf: aDictionary [
	"A named sound is wrapped, so the randomizers and weight given where it is used apply to this use only."

	aDictionary at: 'sound' ifPresent: [ :sampleName | ^ SBSound sampleName: sampleName ].
	aDictionary at: 'use' ifPresent: [ :soundName | ^ SBLayerContainer withAll: { (self namedNode: soundName) } ].
	aDictionary at: 'random' ifPresent: [ :children |
			^ (SBRandomContainer withAll: (self readNodes: children))
				  avoidRepeatCount: (aDictionary at: 'avoidRepeat' ifAbsent: [ 1 ]);
				  yourself ].
	aDictionary at: 'sequence' ifPresent: [ :children | ^ SBSequenceContainer withAll: (self readNodes: children) ].
	aDictionary at: 'layer' ifPresent: [ :children | ^ SBLayerContainer withAll: (self readNodes: children) ].
	aDictionary at: 'every' ifPresent: [ :period | ^ self readCycle: aDictionary period: period ].
	SBBankError signal: 'A sound map needs one of sound, use, random, sequence, layer, or every: ' , aDictionary printString
]

{ #category : 'reading' }
SBBankReader >> sampleNameOf: aFile in: aDirectory [
	"'bell/c5' for <bank>/bell/c5.wav, with forward slashes on every platform."

	^ (aFile withoutExtension relativeTo: aDirectory) segments joinUsing: '/'
]

{ #category : 'reading' }
SBBankReader >> soundExtensions [
	"Formats scsynth decodes."

	^ #( 'wav' 'aif' 'aiff' 'flac' 'ogg' 'mp3' )
]

{ #category : 'reading' }
SBBankReader >> soundFilesIn: aDirectory [

	^ aDirectory allFiles select: [ :file | self soundExtensions includes: file extension asLowercase ]
]
