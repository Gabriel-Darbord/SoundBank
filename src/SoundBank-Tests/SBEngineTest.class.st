"
I test the engine with myself as its server and its only sound: I record each play instead of running scsynth.
"
Class {
	#name : 'SBEngineTest',
	#superclass : 'TestCase',
	#instVars : [
		'played',
		'playedSignal',
		'engine'
	],
	#category : 'SoundBank-Tests',
	#package : 'SoundBank-Tests'
}

{ #category : 'sound protocol' }
SBEngineTest >> free [

	
]

{ #category : 'server protocol' }
SBEngineTest >> isRunning [

	^ true
]

{ #category : 'sound protocol' }
SBEngineTest >> playRate: aRate amplitude: anAmplitude delay: seconds [
	"I stand in for the bank's only sound."

	played add: {
			aRate.
			anAmplitude.
			seconds }.
	playedSignal signal
]

{ #category : 'running' }
SBEngineTest >> setUp [

	super setUp.
	played := OrderedCollection new.
	playedSignal := Semaphore new.
	engine := SBEngine new.
	engine
		server: self;
		bank: (SBBank
				 named: 'test'
				 sounds: (Dictionary new
						  at: 'short' put: self;
						  yourself)
				 events: (Dictionary new
						  at: 'ping' put: (SBSound sampleName: 'short');
						  at: 'chord' put: (SBLayerContainer withAll: {
										   (SBSound sampleName: 'short').
										   ((SBSound sampleName: 'short')
											    delay: (SBRange fixed: 1);
											    yourself) });
						  at: 'broken' put: (SBSound sampleName: 'missing');
						  yourself))
]

{ #category : 'server protocol' }
SBEngineTest >> start [
	"I stand in for the scsynth server."

	
]

{ #category : 'server protocol' }
SBEngineTest >> startSupervising [

	
]

{ #category : 'server protocol' }
SBEngineTest >> stop [

	
]

{ #category : 'running' }
SBEngineTest >> tearDown [

	engine stop.
	super tearDown
]

{ #category : 'tests' }
SBEngineTest >> testEventsPlayWhileTheirPosterIsBusy [
	"Servers handle requests at low I/O priority; a busy request must not hold back its sounds."

	| playedWhileBusy done |
	engine start.
	done := Semaphore new.
	[
		| start |
		engine postNamed: 'ping'.
		start := Time millisecondClockValue.
		[ Time millisecondClockValue - start < 100 ] whileTrue.
		playedWhileBusy := played size.
		done signal ] forkAt: Processor lowIOPriority.
	self deny: (done waitTimeoutMilliseconds: 2000).
	self assert: playedWhileBusy equals: 1
]

{ #category : 'tests' }
SBEngineTest >> testLoadBankKeepsTheCurrentBankOnFailure [

	| bank |
	bank := engine bank.
	self should: [ engine loadBank: FileLocator temp / 'no-such-soundboard-bank' ] raise: SBBankError.
	self assert: engine bank identicalTo: bank
]

{ #category : 'tests' }
SBEngineTest >> testPlaySendsEveryPlayback [

	engine play: (SBEvent named: 'chord').
	self assert: played size equals: 2.
	self assert: played first equals: #( 1 1 0 ).
	self assert: played last last equals: 1 / 1000
]

{ #category : 'tests' }
SBEngineTest >> testPlayerSurvivesErrors [

	engine start.
	engine postNamed: 'broken'.
	engine postNamed: 'ping'.
	self deny: (playedSignal waitTimeoutMilliseconds: 2000).
	self assert: engine lastError class equals: SBBankError.
	self assert: engine isRunning
]

{ #category : 'tests' }
SBEngineTest >> testPostedEventsPlayInTheBackground [

	engine start.
	self assert: engine isRunning.
	engine postNamed: 'ping'.
	self deny: (playedSignal waitTimeoutMilliseconds: 2000).
	self assert: played size equals: 1
]

{ #category : 'tests' }
SBEngineTest >> testPostingWhileStoppedPlaysNothing [

	engine postNamed: 'ping'.
	self deny: engine isRunning.
	self assert: played isEmpty
]

{ #category : 'tests' }
SBEngineTest >> testStopEndsThePlayer [

	engine start.
	engine stop.
	self deny: engine isRunning
]

{ #category : 'tests' }
SBEngineTest >> testUnmappedEventsPlayNothing [

	engine play: (SBEvent named: 'nothing here').
	self assert: played isEmpty
]
