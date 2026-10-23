"
I am the abstract node of a sound hierarchy, like a Wwise sound object. Every node has randomizers: pitch (cents), volume (decibels), and delay (milliseconds). They default to zero.

Subclasses decide what a trigger plays: one sample, nothing, or a choice among children.
"
Class {
	#name : 'SBSoundNode',
	#superclass : 'Object',
	#instVars : [
		'pitch',
		'volume',
		'delay',
		'weight'
	],
	#category : 'SoundBank-Model',
	#package : 'SoundBank',
	#tag : 'Model'
}

{ #category : 'testing' }
SBSoundNode class >> isAbstract [

	^ self == SBSoundNode
]

{ #category : 'accessing' }
SBSoundNode >> delay [
	"Delay in milliseconds."

	^ delay
]

{ #category : 'accessing' }
SBSoundNode >> delay: aRange [

	delay := aRange
]

{ #category : 'initialization' }
SBSoundNode >> initialize [

	super initialize.
	pitch := SBRange zero.
	volume := SBRange zero.
	delay := SBRange zero.
	weight := 1
]

{ #category : 'accessing' }
SBSoundNode >> pitch [
	"Pitch offset in cents."

	^ pitch
]

{ #category : 'accessing' }
SBSoundNode >> pitch: aRange [

	pitch := aRange
]

{ #category : 'triggering' }
SBSoundNode >> playIn: aTrigger [
	"Add my playbacks to aTrigger, whose offsets already include my randomizers."

	self subclassResponsibility
]

{ #category : 'triggering' }
SBSoundNode >> playbacksWith: aRandom [

	| trigger |
	trigger := SBTrigger random: aRandom.
	self triggerIn: trigger.
	^ trigger playbacks
]

{ #category : 'enumerating' }
SBSoundNode >> sampleNamesDo: aBlock [

	self subclassResponsibility
]

{ #category : 'triggering' }
SBSoundNode >> triggerIn: aTrigger [

	self playIn: (aTrigger varyBy: self)
]

{ #category : 'accessing' }
SBSoundNode >> volume [
	"Volume offset in decibels."

	^ volume
]

{ #category : 'accessing' }
SBSoundNode >> volume: aRange [

	volume := aRange
]

{ #category : 'accessing' }
SBSoundNode >> weight [
	"How likely a random container picks me, relative to my siblings (default 1)."

	^ weight
]

{ #category : 'accessing' }
SBSoundNode >> weight: aNumber [

	weight := aNumber
]
