"
I play all my children on every trigger, like a Wwise blend container without blend tracks. Give children different delays to play an arpeggio instead of a chord.
"
Class {
	#name : 'SBLayerContainer',
	#superclass : 'SBContainer',
	#category : 'SoundBank-Model',
	#package : 'SoundBank',
	#tag : 'Model'
}

{ #category : 'triggering' }
SBLayerContainer >> playIn: aTrigger [

	children do: [ :child | child triggerIn: aTrigger ]
]
