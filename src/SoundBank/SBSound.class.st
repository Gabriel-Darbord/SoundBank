"
I am a leaf node that plays one sample, named by its path in the bank without extension, such as 'bell/c5'.
"
Class {
	#name : 'SBSound',
	#superclass : 'SBSoundNode',
	#instVars : [
		'sampleName'
	],
	#category : 'SoundBank-Model',
	#package : 'SoundBank',
	#tag : 'Model'
}

{ #category : 'instance creation' }
SBSound class >> sampleName: aName [

	^ self new
		  sampleName: aName;
		  yourself
]

{ #category : 'triggering' }
SBSound >> playIn: aTrigger [

	aTrigger playSampleNamed: sampleName
]

{ #category : 'accessing' }
SBSound >> sampleName [

	^ sampleName
]

{ #category : 'accessing' }
SBSound >> sampleName: aName [

	sampleName := aName
]

{ #category : 'enumerating' }
SBSound >> sampleNamesDo: aBlock [

	aBlock value: sampleName
]
