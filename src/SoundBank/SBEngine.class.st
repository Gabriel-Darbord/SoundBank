"
I am the sound engine. Clients post events; my player process resolves each event in the current bank and has a SuperCollider server (scsynth, a separate process, through Scsynth) play the sounds.

Posting only enqueues, so it never blocks the caller, and playing only sends UDP messages. All audio runs in scsynth: if it crashes, the image keeps running and the server is restarted. All container state (round-robin positions, recently played children) is touched only by the player process.

	SBEngine default
		start;
		loadBank: 'path/to/bank';
		postNamed: 'tests.success'.

Errors while playing are logged to the Transcript and kept in lastError; they never reach the poster.
"
Class {
	#name : 'SBEngine',
	#superclass : 'Object',
	#instVars : [
		'bank',
		'random',
		'pending',
		'player',
		'lastError',
		'server'
	],
	#classInstVars : [
		'default'
	],
	#category : 'SoundBank-Engine',
	#package : 'SoundBank',
	#tag : 'Engine'
}

{ #category : 'accessing' }
SBEngine class >> default [

	^ default ifNil: [ default := self new ]
]

{ #category : 'class initialization' }
SBEngine class >> reset [

	<script>
	default ifNotNil: [ :engine | engine stop ].
	default := nil
]

{ #category : 'accessing' }
SBEngine >> bank [

	^ bank
]

{ #category : 'accessing' }
SBEngine >> bank: aSoundBank [

	bank := aSoundBank
]

{ #category : 'playing' }
SBEngine >> handle: anEvent [

	[ self play: anEvent ]
		on: Error
		do: [ :error | self reportError: error ]
]

{ #category : 'initialization' }
SBEngine >> initialize [

	super initialize.
	bank := SBBank empty.
	server := ScsynthServer new.
	random := Random new.
	pending := SharedQueue new
]

{ #category : 'running' }
SBEngine >> isRunning [

	^ player isNotNil and: [ player isTerminated not ]
]

{ #category : 'accessing' }
SBEngine >> lastError [

	^ lastError
]

{ #category : 'accessing' }
SBEngine >> loadBank: aDirectory [
	"Load the new bank before swapping it in, so a broken bank leaves the current one playing."

	| loaded previous |
	server isRunning ifFalse: [ server start ].
	loaded := SBBank fromDirectory: aDirectory server: server.
	previous := bank.
	bank := loaded.
	previous free
]

{ #category : 'playing' }
SBEngine >> play: anEvent [
	"Play anEvent from the calling process. Each playback is one OSC message to the server; nothing waits."

	(bank playbacksFor: anEvent with: random) do: [ :playback | bank play: playback ]
]

{ #category : 'posting' }
SBEngine >> post: anEvent [
	"Enqueue anEvent for the player process. Answer immediately."

	self isRunning ifTrue: [ pending nextPut: anEvent ]
]

{ #category : 'posting' }
SBEngine >> postNamed: aKey [

	self post: (SBEvent named: aKey)
]

{ #category : 'accessing' }
SBEngine >> random: aRandom [

	random := aRandom
]

{ #category : 'playing' }
SBEngine >> reportError: anError [

	lastError := anError.
	('SoundBank: ' , anError description) traceCr
]

{ #category : 'accessing' }
SBEngine >> server [

	^ server
]

{ #category : 'accessing' }
SBEngine >> server: anScsynthServer [

	server := anScsynthServer
]

{ #category : 'running' }
SBEngine >> start [
	"Start the audio server, keep it supervised, and play posted events in a process at I/O priority, so sounds come while the image is busy with whatever triggered them, even from a server's worker process. Playing only sends a few datagrams, so it never holds the processor for long."

	server start.
	server startSupervising.
	self isRunning ifTrue: [ ^ self ].
	player := [ [ self handle: pending next ] repeat ] forkAt: Processor highIOPriority named: 'SoundBank player'
]

{ #category : 'running' }
SBEngine >> stop [

	player ifNotNil: [ :process | process terminate ].
	player := nil.
	pending removeAll.
	server stop
]
