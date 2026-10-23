"
I count triggers. Cycle containers that share me count together: with one counter 'magazine' shared by several events, the 8th trigger of any of them is the 8th of the magazine.
"
Class {
	#name : 'SBCounter',
	#superclass : 'Object',
	#instVars : [
		'count'
	],
	#category : 'SoundBank-Model',
	#package : 'SoundBank',
	#tag : 'Model'
}

{ #category : 'counting' }
SBCounter >> count [

	^ count
]

{ #category : 'initialization' }
SBCounter >> initialize [

	super initialize.
	count := 0
]

{ #category : 'counting' }
SBCounter >> next [
	"Count one more trigger and answer the new count."

	count := count + 1.
	^ count
]
