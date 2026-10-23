"
I am a node that plays nothing. A bank maps an event to me to mute it explicitly, which also stops the lookup from falling back to more general events.
"
Class {
	#name : 'SBSilence',
	#superclass : 'SBSoundNode',
	#category : 'SoundBank-Model',
	#package : 'SoundBank',
	#tag : 'Model'
}

{ #category : 'triggering' }
SBSilence >> playIn: aTrigger [
	"Play nothing."

	
]

{ #category : 'enumerating' }
SBSilence >> sampleNamesDo: aBlock [
	"I reference no sample."

	
]
