"
I am a randomizer: an inclusive interval of numbers from which a uniform random value is drawn on each trigger. A fixed value is a range whose minimum equals its maximum.

Sound nodes use me for pitch offsets in cents, volume offsets in decibels, and delays in milliseconds.
"
Class {
	#name : 'SBRange',
	#superclass : 'Object',
	#instVars : [
		'minimum',
		'maximum'
	],
	#category : 'SoundBank-Model',
	#package : 'SoundBank',
	#tag : 'Model'
}

{ #category : 'instance creation' }
SBRange class >> fixed: aNumber [

	^ self from: aNumber to: aNumber
]

{ #category : 'instance creation' }
SBRange class >> from: aMinimum to: aMaximum [

	^ self new
		  setMinimum: (aMinimum min: aMaximum) maximum: (aMinimum max: aMaximum);
		  yourself
]

{ #category : 'instance creation' }
SBRange class >> zero [

	^ self fixed: 0
]

{ #category : 'comparing' }
SBRange >> = anObject [

	self == anObject ifTrue: [ ^ true ].
	self class = anObject class ifFalse: [ ^ false ].
	^ minimum = anObject minimum and: [ maximum = anObject maximum ]
]

{ #category : 'comparing' }
SBRange >> hash [

	^ minimum hash bitXor: maximum hash
]

{ #category : 'accessing' }
SBRange >> maximum [

	^ maximum
]

{ #category : 'accessing' }
SBRange >> minimum [

	^ minimum
]

{ #category : 'printing' }
SBRange >> printOn: aStream [

	aStream print: minimum.
	minimum = maximum ifFalse: [
			aStream
				nextPutAll: ' to: ';
				print: maximum ]
]

{ #category : 'initialization' }
SBRange >> setMinimum: aMinimum maximum: aMaximum [

	minimum := aMinimum.
	maximum := aMaximum
]

{ #category : 'accessing' }
SBRange >> valueFrom: aRandom [

	minimum = maximum ifTrue: [ ^ minimum ].
	^ minimum + (aRandom next * (maximum - minimum))
]
