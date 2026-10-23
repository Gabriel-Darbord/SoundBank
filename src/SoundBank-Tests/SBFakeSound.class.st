"
I stand in for an ScsynthSound in tests: I record each play as an Array of rate, amplitude, and delay, and whether I was freed.
"
Class {
	#name : 'SBFakeSound',
	#superclass : 'Object',
	#instVars : [
		'plays',
		'freed'
	],
	#category : 'SoundBank-Tests',
	#package : 'SoundBank-Tests'
}

{ #category : 'sound protocol' }
SBFakeSound >> free [

	freed := true
]

{ #category : 'initialization' }
SBFakeSound >> initialize [

	super initialize.
	plays := OrderedCollection new.
	freed := false
]

{ #category : 'accessing' }
SBFakeSound >> isFreed [

	^ freed
]

{ #category : 'sound protocol' }
SBFakeSound >> playRate: aRate amplitude: anAmplitude delay: seconds [

	plays add: {
			aRate.
			anAmplitude.
			seconds }
]

{ #category : 'accessing' }
SBFakeSound >> plays [

	^ plays
]
