"
I am an abstract node with child nodes. Subclasses decide which children a trigger plays.
"
Class {
	#name : 'SBContainer',
	#superclass : 'SBSoundNode',
	#instVars : [
		'children'
	],
	#category : 'SoundBank-Model',
	#package : 'SoundBank',
	#tag : 'Model'
}

{ #category : 'testing' }
SBContainer class >> isAbstract [

	^ self == SBContainer
]

{ #category : 'instance creation' }
SBContainer class >> withAll: someNodes [

	^ self new
		  children: someNodes;
		  yourself
]

{ #category : 'accessing' }
SBContainer >> children [

	^ children
]

{ #category : 'accessing' }
SBContainer >> children: someNodes [

	children := someNodes asArray
]

{ #category : 'initialization' }
SBContainer >> initialize [

	super initialize.
	children := #(  )
]

{ #category : 'enumerating' }
SBContainer >> sampleNamesDo: aBlock [

	children do: [ :child | child sampleNamesDo: aBlock ]
]
