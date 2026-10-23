"
I play my children one per trigger, in order, wrapping around at the end (round-robin), like a Wwise sequence container in continuous loop mode.
"
Class {
	#name : 'SBSequenceContainer',
	#superclass : 'SBContainer',
	#instVars : [
		'position'
	],
	#category : 'SoundBank-Model',
	#package : 'SoundBank',
	#tag : 'Model'
}

{ #category : 'initialization' }
SBSequenceContainer >> initialize [

	super initialize.
	position := 0
]

{ #category : 'triggering' }
SBSequenceContainer >> playIn: aTrigger [

	children ifEmpty: [ ^ self ].
	position := position \\ children size + 1.
	(children at: position) triggerIn: aTrigger
]
