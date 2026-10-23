"
I test sound nodes, containers, and randomizers without audio: triggering a node only produces playbacks.
"
Class {
	#name : 'SBSoundNodeTest',
	#superclass : 'TestCase',
	#instVars : [
		'random'
	],
	#category : 'SoundBank-Tests',
	#package : 'SoundBank-Tests'
}

{ #category : 'helpers' }
SBSoundNodeTest >> sampleNamesPlayedBy: aNode times: aCount [

	^ (1 to: aCount) collect: [ :index | ((aNode playbacksWith: random) collect: [ :playback | playback sampleName ]) asArray ]
]

{ #category : 'running' }
SBSoundNodeTest >> setUp [

	super setUp.
	random := Random seed: 42
]

{ #category : 'helpers' }
SBSoundNodeTest >> sound: aName [

	^ SBSound sampleName: aName
]

{ #category : 'tests' }
SBSoundNodeTest >> testCyclePlaysTheSpecialNodeOnEveryNthTrigger [

	| cycle |
	cycle := SBCycleContainer
		         counter: SBCounter new
		         period: 3
		         special: (self sound: 'special')
		         regular: (self sound: 'regular').
	self
		assert: ((self sampleNamesPlayedBy: cycle times: 7) collect: [ :names | names first ])
		equals: #( 'regular' 'regular' 'special' 'regular' 'regular' 'special' 'regular' )
]

{ #category : 'tests' }
SBSoundNodeTest >> testCyclesSharingACounterCountTogether [

	| counter first second played |
	counter := SBCounter new.
	first := SBCycleContainer
		         counter: counter
		         period: 4
		         special: (self sound: 'first special')
		         regular: (self sound: 'first').
	second := SBCycleContainer
		          counter: counter
		          period: 4
		          special: (self sound: 'second special')
		          regular: (self sound: 'second').
	played := OrderedCollection new.
	3 timesRepeat: [ played add: (first playbacksWith: random) first sampleName ].
	played add: (second playbacksWith: random) first sampleName.
	self assert: played asArray equals: #( 'first' 'first' 'first' 'second special' )
]

{ #category : 'tests' }
SBSoundNodeTest >> testEmptyContainersPlayNothing [

	{
		SBRandomContainer new.
		SBSequenceContainer new.
		SBLayerContainer new } do: [ :container | self assert: (container playbacksWith: random) isEmpty ]
]

{ #category : 'tests' }
SBSoundNodeTest >> testLayerPlaysAllChildren [

	| layer |
	layer := SBLayerContainer withAll: {
			         (self sound: 'a').
			         (self sound: 'b').
			         (self sound: 'c') }.
	self assert: (self sampleNamesPlayedBy: layer times: 2) equals: #( #( 'a' 'b' 'c' ) #( 'a' 'b' 'c' ) )
]

{ #category : 'tests' }
SBSoundNodeTest >> testNegativeDelaysClampToZero [

	| sound |
	sound := self sound: 'a'.
	sound delay: (SBRange fixed: -40).
	self assert: (sound playbacksWith: random) first delayMilliseconds equals: 0
]

{ #category : 'tests' }
SBSoundNodeTest >> testRandomAvoidsRepeatingRecentChildren [

	| container played |
	container := SBRandomContainer withAll: {
			             (self sound: 'a').
			             (self sound: 'b').
			             (self sound: 'c') }.
	container avoidRepeatCount: 2.
	played := (self sampleNamesPlayedBy: container times: 60) collect: [ :names | names first ].
	1 to: played size - 2 do: [ :index | self assert: (played copyFrom: index to: index + 2) asSet size equals: 3 ]
]

{ #category : 'tests' }
SBSoundNodeTest >> testRandomPlaysEveryChildEventually [

	| container played |
	container := SBRandomContainer withAll: {
			             (self sound: 'a').
			             (self sound: 'b').
			             (self sound: 'c').
			             (self sound: 'd') }.
	played := (self sampleNamesPlayedBy: container times: 100) collect: [ :names | names first ].
	self assert: played asSet equals: #( 'a' 'b' 'c' 'd' ) asSet.
	1 to: played size - 1 do: [ :index | self deny: (played at: index) equals: (played at: index + 1) ]
]

{ #category : 'tests' }
SBSoundNodeTest >> testRandomWithOneChildAlwaysPlaysIt [

	| container |
	container := SBRandomContainer withAll: { (self sound: 'only') }.
	self assert: (self sampleNamesPlayedBy: container times: 3) equals: #( #( 'only' ) #( 'only' ) #( 'only' ) )
]

{ #category : 'tests' }
SBSoundNodeTest >> testRandomizersAccumulateFromContainerToChild [

	| child layer playback |
	child := self sound: 'a'.
	child
		pitch: (SBRange fixed: 100);
		volume: (SBRange fixed: -3);
		delay: (SBRange fixed: 20).
	layer := SBLayerContainer withAll: { child }.
	layer
		pitch: (SBRange fixed: 1100);
		volume: (SBRange fixed: -6);
		delay: (SBRange fixed: 30).
	playback := (layer playbacksWith: random) first.
	self assert: playback pitchCents equals: 1200.
	self assert: playback pitchRatio closeTo: 2.
	self assert: playback volumeDecibels equals: -9.
	self assert: playback delayMilliseconds equals: 50
]

{ #category : 'tests' }
SBSoundNodeTest >> testRandomizersDrawWithinTheirRange [

	| sound values |
	sound := self sound: 'a'.
	sound pitch: (SBRange from: 50 to: -50).
	values := (1 to: 100) collect: [ :index | (sound playbacksWith: random) first pitchCents ].
	self assert: (values allSatisfy: [ :cents | cents between: -50 and: 50 ]).
	self assert: values asSet size > 1
]

{ #category : 'tests' }
SBSoundNodeTest >> testSequencePlaysChildrenRoundRobin [

	| sequence |
	sequence := SBSequenceContainer withAll: {
			            (self sound: 'a').
			            (self sound: 'b').
			            (self sound: 'c') }.
	self assert: (self sampleNamesPlayedBy: sequence times: 5) equals: #( #( 'a' ) #( 'b' ) #( 'c' ) #( 'a' ) #( 'b' ) )
]

{ #category : 'tests' }
SBSoundNodeTest >> testSiblingsDoNotShareOffsets [

	| first layer playbacks |
	first := self sound: 'a'.
	first delay: (SBRange fixed: 100).
	layer := SBLayerContainer withAll: {
			         first.
			         (self sound: 'b') }.
	playbacks := layer playbacksWith: random.
	self assert: (playbacks collect: [ :playback | playback delayMilliseconds ]) asArray equals: #( 100 0 )
]

{ #category : 'tests' }
SBSoundNodeTest >> testSilencePlaysNothing [

	self assert: (SBSilence new playbacksWith: random) isEmpty
]

{ #category : 'tests' }
SBSoundNodeTest >> testSoundPlaysItsSample [

	| playbacks |
	playbacks := (self sound: 'bell/c5') playbacksWith: random.
	self assert: playbacks size equals: 1.
	self assert: playbacks first sampleName equals: 'bell/c5'.
	self assert: playbacks first pitchRatio equals: 1.
	self assert: playbacks first gain equals: 1
]

{ #category : 'tests' }
SBSoundNodeTest >> testWeightsSkewRandomChoices [
	"Weights 3 and 1: about three quarters of 400 picks go to the heavy child."

	| heavy container heavyCount |
	heavy := self sound: 'heavy'.
	heavy weight: 3.
	container := SBRandomContainer withAll: {
			             heavy.
			             (self sound: 'light') }.
	container avoidRepeatCount: 0.
	heavyCount := (self sampleNamesPlayedBy: container times: 400) count: [ :names | names first = 'heavy' ].
	self assert: (heavyCount between: 260 and: 340)
]

{ #category : 'tests' }
SBSoundNodeTest >> testZeroWeightIsNeverPicked [

	| never container |
	never := self sound: 'never'.
	never weight: 0.
	container := SBRandomContainer withAll: {
			             never.
			             (self sound: 'always') }.
	container avoidRepeatCount: 0.
	self assert: ((self sampleNamesPlayedBy: container times: 50) allSatisfy: [ :names | names first = 'always' ])
]
