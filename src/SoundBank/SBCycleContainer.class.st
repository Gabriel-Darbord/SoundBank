"
I play my special node on every period-th trigger of my counter, and my regular node otherwise. Sharing the counter with other cycle containers makes them count together.

	{ 'every' : 8, 'counter' : 'magazine', 'then' : 'last-shot', 'otherwise' : 'shot' }
"
Class {
	#name : 'SBCycleContainer',
	#superclass : 'SBSoundNode',
	#instVars : [
		'counter',
		'period',
		'special',
		'regular'
	],
	#category : 'SoundBank-Model',
	#package : 'SoundBank',
	#tag : 'Model'
}

{ #category : 'instance creation' }
SBCycleContainer class >> counter: aCounter period: anInteger special: aSpecialNode regular: aRegularNode [

	^ self new
		  setCounter: aCounter
		  period: anInteger
		  special: aSpecialNode
		  regular: aRegularNode;
		  yourself
]

{ #category : 'accessing' }
SBCycleContainer >> counter [

	^ counter
]

{ #category : 'accessing' }
SBCycleContainer >> period [

	^ period
]

{ #category : 'triggering' }
SBCycleContainer >> playIn: aTrigger [

	(counter next \\ period = 0
		 ifTrue: [ special ]
		 ifFalse: [ regular ]) triggerIn: aTrigger
]

{ #category : 'accessing' }
SBCycleContainer >> regular [

	^ regular
]

{ #category : 'enumerating' }
SBCycleContainer >> sampleNamesDo: aBlock [

	special sampleNamesDo: aBlock.
	regular sampleNamesDo: aBlock
]

{ #category : 'initialization' }
SBCycleContainer >> setCounter: aCounter period: anInteger special: aSpecialNode regular: aRegularNode [

	counter := aCounter.
	period := anInteger.
	special := aSpecialNode.
	regular := aRegularNode
]

{ #category : 'accessing' }
SBCycleContainer >> special [

	^ special
]
