"
I test event lookup and validation in a bank built in memory.
"
Class {
	#name : 'SBBankTest',
	#superclass : 'TestCase',
	#category : 'SoundBank-Tests',
	#package : 'SoundBank-Tests'
}

{ #category : 'helpers' }
SBBankTest >> bankWithEvents: aDictionary [

	^ SBBank
		  named: 'test'
		  sounds: (#( 'a' 'b' 'c' ) inject: Dictionary new into: [ :sounds :name |
					   sounds at: name put: SBFakeSound new.
					   sounds ])
		  events: aDictionary
]

{ #category : 'helpers' }
SBBankTest >> sampleNamesFor: anEvent in: aBank [

	^ ((aBank playbacksFor: anEvent with: Random new) collect: [ :playback | playback sampleName ]) asArray
]

{ #category : 'tests' }
SBBankTest >> testAMoreImportantPhaseBeatsAMoreSpecificSubject [

	| bank |
	bank := self bankWithEvents: (Dictionary new
			         at: 'method_compile.success' put: (SBSound sampleName: 'a');
			         at: '*.recovered' put: (SBSound sampleName: 'b');
			         yourself).
	self
		assert: (self sampleNamesFor: (SBEvent subjects: #( 'method_compile' '*' ) phases: #( 'recovered' 'success' )) in: bank)
		equals: #( 'b' )
]

{ #category : 'tests' }
SBBankTest >> testBankLooksUpSets [

	| bank |
	bank := SBBank
		        named: 'test'
		        sounds: Dictionary new
		        events: (Dictionary new
				         at: 'edit.start' put: (SBSound sampleName: 'shot');
				         at: '*.start' put: (SBSound sampleName: 'other');
				         yourself)
		        sets: (Dictionary new
				         at: 'edit' put: #( 'method_rewrite' );
				         yourself).
	self assert: (bank nodeFor: (SBEvent subjects: #( 'method_rewrite' '*' ) phases: #( 'start' ))) sampleName equals: 'shot'.
	self assert: (bank nodeFor: (SBEvent subjects: #( 'class_get' '*' ) phases: #( 'start' ))) sampleName equals: 'other'.
	self assert: (bank setsContaining: 'method_rewrite') equals: #( 'edit' )
]

{ #category : 'tests' }
SBBankTest >> testExplicitSilenceStopsFallback [

	| bank |
	bank := self bankWithEvents: (Dictionary new
			         at: '*.success' put: (SBSound sampleName: 'a');
			         at: 'method_compile.success' put: SBSilence new;
			         yourself).
	self assert: (self sampleNamesFor: (self toolEvent: 'success') in: bank) isEmpty
]

{ #category : 'tests' }
SBBankTest >> testFreeReleasesEverySound [

	| bank |
	bank := self bankWithEvents: Dictionary new.
	bank free.
	self assert: (bank sampleNames allSatisfy: [ :name | (bank soundNamed: name) isFreed ])
]

{ #category : 'tests' }
SBBankTest >> testKeysGoPhaseByPhaseThroughSubjects [

	| event |
	event := SBEvent subjects: #( 'test_run' 'tests' '*' ) phases: #( 'recovered' 'success' ).
	self
		assert: event keys
		equals: #( 'test_run.recovered' 'tests.recovered' '*.recovered' 'test_run.success' 'tests.success' '*.success' )
]

{ #category : 'tests' }
SBBankTest >> testLookupFallsBackThroughGroupAccessAndWildcard [

	| events bank |
	events := Dictionary new.
	bank := self bankWithEvents: events.
	events at: '*.success' put: (SBSound sampleName: 'a').
	self assert: (self sampleNamesFor: (self toolEvent: 'success') in: bank) equals: #( 'a' ).
	events at: 'write.success' put: (SBSound sampleName: 'b').
	self assert: (self sampleNamesFor: (self toolEvent: 'success') in: bank) equals: #( 'b' ).
	events at: 'methods.success' put: (SBSound sampleName: 'c').
	self assert: (self sampleNamesFor: (self toolEvent: 'success') in: bank) equals: #( 'c' )
]

{ #category : 'tests' }
SBBankTest >> testMostSpecificKeyWins [

	| bank |
	bank := self bankWithEvents: (Dictionary new
			         at: '*.success' put: (SBSound sampleName: 'a');
			         at: 'write.success' put: (SBSound sampleName: 'b');
			         at: 'method_compile.success' put: (SBSound sampleName: 'c');
			         yourself).
	self assert: (self sampleNamesFor: (self toolEvent: 'success') in: bank) equals: #( 'c' )
]

{ #category : 'tests' }
SBBankTest >> testNamedEventUsesItsNameOnly [

	| bank |
	bank := self bankWithEvents: (Dictionary new
			         at: 'custom' put: (SBSound sampleName: 'b');
			         yourself).
	self assert: (self sampleNamesFor: (SBEvent named: 'custom') in: bank) equals: #( 'b' )
]

{ #category : 'tests' }
SBBankTest >> testPlaySendsPitchVolumeAndDelayToTheSound [

	| bank sound |
	bank := self bankWithEvents: Dictionary new.
	sound := bank soundNamed: 'b'.
	bank play: (SBPlayback
			 sampleName: 'b'
			 pitchCents: 1200
			 volumeDecibels: -20
			 delayMilliseconds: 250).
	self assert: sound plays size equals: 1.
	self assert: sound plays first first closeTo: 2.
	self assert: (sound plays first at: 2) closeTo: 0.1.
	self assert: sound plays first last equals: 1 / 4
]

{ #category : 'tests' }
SBBankTest >> testSetsFollowTheSubjectTheyContain [

	| event |
	event := SBEvent subjects: #( 'method_rewrite' 'methods' '*' ) phases: #( 'start' ).
	self
		assert: (event keysExpandingSubjectsWith: (Dictionary new
					  at: 'method_rewrite' put: #( 'edit' 'loud' );
					  yourself))
		equals: #( 'method_rewrite.start' 'edit.start' 'loud.start' 'methods.start' '*.start' )
]

{ #category : 'tests' }
SBBankTest >> testUnknownSampleIsAnError [

	self should: [ (self bankWithEvents: Dictionary new) soundNamed: 'nope' ] raise: SBBankError
]

{ #category : 'tests' }
SBBankTest >> testUnmappedEventPlaysNothing [

	self assert: (self sampleNamesFor: (self toolEvent: 'start') in: (self bankWithEvents: Dictionary new)) isEmpty
]

{ #category : 'tests' }
SBBankTest >> testUnusedSamples [

	| bank |
	bank := self bankWithEvents: (Dictionary new
			         at: 'x' put: (SBRandomContainer withAll: { (SBSound sampleName: 'a') });
			         at: 'y' put: SBSilence new;
			         yourself).
	self assert: bank unusedSampleNames equals: #( 'b' 'c' )
]

{ #category : 'tests' }
SBBankTest >> testValidateReportsMissingSamples [

	| bank |
	bank := self bankWithEvents: (Dictionary new
			         at: 'x' put: (SBLayerContainer withAll: {
							          (SBSound sampleName: 'a').
							          (SBSound sampleName: 'zz').
							          (SBSound sampleName: 'yy') });
			         yourself).
	self assert: bank missingSampleNames equals: #( 'yy' 'zz' ).
	self should: [ bank validate ] raise: SBBankError
]

{ #category : 'helpers' }
SBBankTest >> toolEvent: aPhase [
	"Keys like the ones a tool call produces, most specific first."

	^ SBEvent keys: ({ 'method_compile'. 'methods'. 'write'. '*' } collect: [ :subject | subject , '.' , aPhase ])
]
