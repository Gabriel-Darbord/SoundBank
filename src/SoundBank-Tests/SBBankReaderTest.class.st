"
I test reading sound descriptions from bank.ston values.
"
Class {
	#name : 'SBBankReaderTest',
	#superclass : 'TestCase',
	#instVars : [
		'reader'
	],
	#category : 'SoundBank-Tests',
	#package : 'SoundBank-Tests'
}

{ #category : 'helpers' }
SBBankReaderTest >> read: aStonString [

	^ reader readNode: (STON fromString: aStonString)
]

{ #category : 'running' }
SBBankReaderTest >> setUp [

	super setUp.
	reader := SBBankReader new
]

{ #category : 'tests' }
SBBankReaderTest >> testCyclesNamingACounterShareIt [

	| first second |
	first := self read: '{ ''every'' : 8, ''counter'' : ''magazine'', ''then'' : ''a'' }'.
	second := self read: '{ ''every'' : 8, ''counter'' : ''magazine'', ''then'' : ''b'' }'.
	self assert: first counter identicalTo: second counter.
	self deny: (self read: '{ ''every'' : 8, ''then'' : ''a'' }') counter identicalTo: first counter
]

{ #category : 'tests' }
SBBankReaderTest >> testEveryNeedsThenAndAPositivePeriod [

	self should: [ self read: '{ ''every'' : 8, ''otherwise'' : ''a'' }' ] raise: SBBankError.
	self should: [ self read: '{ ''every'' : 0, ''then'' : ''a'' }' ] raise: SBBankError
]

{ #category : 'tests' }
SBBankReaderTest >> testEveryReadsACycle [

	| cycle |
	cycle := self read: '{ ''every'' : 8, ''counter'' : ''magazine'', ''then'' : ''last'', ''otherwise'' : [ ''a'', ''b'' ] }'.
	self assert: cycle period equals: 8.
	self assert: cycle special sampleName equals: 'last'.
	self assert: cycle regular children size equals: 2
]

{ #category : 'tests' }
SBBankReaderTest >> testListIsARandomContainer [

	| node |
	node := self read: '[ ''a'', ''b'' ]'.
	self assert: (node children collect: [ :child | child sampleName ]) equals: #( 'a' 'b' ).
	self assert: node avoidRepeatCount equals: 1.
	self assert: ((node playbacksWith: Random new) collect: [ :playback | playback sampleName ]) size equals: 1
]

{ #category : 'tests' }
SBBankReaderTest >> testMalformedRangeIsAnError [

	self should: [ self read: '{ ''sound'' : ''a'', ''pitch'' : [ 1, 2, 3 ] }' ] raise: SBBankError
]

{ #category : 'tests' }
SBBankReaderTest >> testMapReadsStructureAndRandomizers [

	| node |
	node := self read:
		        '{ ''random'' : [ ''a'', { ''sound'' : ''b'', ''delay'' : 80 } ], ''avoidRepeat'' : 0, ''pitch'' : [ -10, 10 ], ''volume'' : -6 }'.
	self assert: node avoidRepeatCount equals: 0.
	self assert: node pitch equals: (SBRange from: -10 to: 10).
	self assert: node volume equals: (SBRange fixed: -6).
	self assert: node delay equals: SBRange zero.
	self assert: node children last delay equals: (SBRange fixed: 80)
]

{ #category : 'tests' }
SBBankReaderTest >> testMapWithoutStructureIsAnError [

	self should: [ self read: '{ ''volume'' : -6 }' ] raise: SBBankError
]

{ #category : 'tests' }
SBBankReaderTest >> testNamedSoundsCannotUseThemselves [

	reader defineSounds: (STON fromString: '{ ''a'' : { ''use'' : ''b'' }, ''b'' : { ''use'' : ''a'' } }').
	self should: [ self read: '{ ''use'' : ''a'' }' ] raise: SBBankError
]

{ #category : 'tests' }
SBBankReaderTest >> testNamedSoundsMayUseEachOther [

	| node |
	reader defineSounds: (STON fromString: '{ ''a'' : { ''use'' : ''b'' }, ''b'' : ''sample'' }').
	node := self read: '{ ''use'' : ''a'' }'.
	self assert: ((node playbacksWith: Random new) collect: [ :playback | playback sampleName ]) asArray equals: #( 'sample' )
]

{ #category : 'tests' }
SBBankReaderTest >> testNilIsSilence [

	self assert: ((self read: 'nil') playbacksWith: Random new) isEmpty
]

{ #category : 'tests' }
SBBankReaderTest >> testReadEventsKeepsExplicitSilence [

	| events |
	events := reader readEvents: (STON fromString: '{ ''a.start'' : nil, ''a.success'' : ''x'' }').
	self assert: events keys asSet equals: #( 'a.start' 'a.success' ) asSet.
	self assert: ((events at: 'a.start') playbacksWith: Random new) isEmpty
]

{ #category : 'tests' }
SBBankReaderTest >> testSequenceAndLayerMaps [

	self assert: ((self read: '{ ''sequence'' : [ ''a'', ''b'' ] }') playbacksWith: Random new) first sampleName equals: 'a'.
	self assert: ((self read: '{ ''layer'' : [ ''a'', ''b'' ] }') playbacksWith: Random new) size equals: 2
]

{ #category : 'tests' }
SBBankReaderTest >> testSetsMustBeListsOfNames [

	self assert: (reader readSets: (STON fromString: '{ ''edit'' : [ ''a'', ''b'' ] }')) size equals: 1.
	self should: [ reader readSets: (STON fromString: '{ ''edit'' : ''a'' }') ] raise: SBBankError
]

{ #category : 'tests' }
SBBankReaderTest >> testStringIsASound [

	| node |
	node := self read: '''bell/c5'''.
	self assert: node sampleName equals: 'bell/c5'.
	self assert: node pitch equals: SBRange zero
]

{ #category : 'tests' }
SBBankReaderTest >> testUnknownKeyIsAnError [

	self should: [ self read: '{ ''sound'' : ''a'', ''volumme'' : -6 }' ] raise: SBBankError
]

{ #category : 'tests' }
SBBankReaderTest >> testUnknownNamedSoundIsAnError [

	self should: [ self read: '{ ''use'' : ''nothing'' }' ] raise: SBBankError
]

{ #category : 'tests' }
SBBankReaderTest >> testUnreadableValueIsAnError [

	self should: [ self read: '42' ] raise: SBBankError
]

{ #category : 'tests' }
SBBankReaderTest >> testUseSharesTheNamedSound [

	| first second |
	reader defineSounds: (STON fromString: '{ ''shot'' : { ''sequence'' : [ ''a'', ''b'' ] } }').
	first := self read: '{ ''use'' : ''shot'' }'.
	second := self read: '{ ''use'' : ''shot'', ''volume'' : -6 }'.
	self assert: first children first identicalTo: second children first.
	self assert: second volume equals: (SBRange fixed: -6).
	self assert: first volume equals: SBRange zero
]

{ #category : 'tests' }
SBBankReaderTest >> testWeight [

	self assert: (self read: '{ ''sound'' : ''a'', ''weight'' : 0.25 }') weight equals: 0.25.
	self assert: (self read: '''a''') weight equals: 1
]
