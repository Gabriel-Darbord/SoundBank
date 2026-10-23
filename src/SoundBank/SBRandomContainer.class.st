"
I play one child chosen at random, like a Wwise random container. I avoid repeating the last avoidRepeatCount children played (default 1), as long as other children remain to choose from.
"
Class {
	#name : 'SBRandomContainer',
	#superclass : 'SBContainer',
	#instVars : [
		'avoidRepeatCount',
		'recentChildren'
	],
	#category : 'SoundBank-Model',
	#package : 'SoundBank',
	#tag : 'Model'
}

{ #category : 'accessing' }
SBRandomContainer >> avoidRepeatCount [

	^ avoidRepeatCount
]

{ #category : 'accessing' }
SBRandomContainer >> avoidRepeatCount: aNumber [

	avoidRepeatCount := aNumber
]

{ #category : 'accessing' }
SBRandomContainer >> children: someNodes [

	super children: someNodes.
	recentChildren removeAll
]

{ #category : 'triggering' }
SBRandomContainer >> chooseChildWith: aTrigger [

	| child |
	child := aTrigger pickFrom: (children reject: [ :each | recentChildren includes: each ]).
	self remember: child.
	^ child
]

{ #category : 'initialization' }
SBRandomContainer >> initialize [

	super initialize.
	avoidRepeatCount := 1.
	recentChildren := OrderedCollection new
]

{ #category : 'triggering' }
SBRandomContainer >> playIn: aTrigger [

	children ifEmpty: [ ^ self ].
	(self chooseChildWith: aTrigger) triggerIn: aTrigger
]

{ #category : 'triggering' }
SBRandomContainer >> remember: aChild [
	"Never remember every child, so at least one candidate always remains."

	recentChildren addLast: aChild.
	[ recentChildren size > (avoidRepeatCount min: children size - 1) ] whileTrue: [ recentChildren removeFirst ]
]
