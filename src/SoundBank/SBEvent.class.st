"
I am something that happened and may play a sound. I hold subjects, from most to least specific, and phases, from most to least important; my keys are subject.phase for each phase in turn, each subject followed by the bank sets that contain it. The first key a bank maps wins, so a more important phase beats a more specific subject.

	SBEvent subjects: #( 'method_compile' 'methods' '*' ) phases: #( 'recovered' 'success' ).
	""method_compile.recovered, edit.recovered (if a set contains it), methods.recovered, *.recovered, method_compile.success, ...""

	SBEvent named: 'tests.success'.     ""exactly that key""

Clients choose their subjects and phases. MCP-Sonification, for example, adds constructors that turn a tool call into subjects from the tool's name, group, and read or write access.
"
Class {
	#name : 'SBEvent',
	#superclass : 'Object',
	#instVars : [
		'subjects',
		'phases'
	],
	#category : 'SoundBank-Model',
	#package : 'SoundBank',
	#tag : 'Model'
}

{ #category : 'instance creation' }
SBEvent class >> keys: someKeys [
	"Literal keys, most specific first, with no structure for sets to expand."

	^ self subjects: someKeys phases: #(  )
]

{ #category : 'instance creation' }
SBEvent class >> named: aKey [

	^ self keys: { aKey }
]

{ #category : 'instance creation' }
SBEvent class >> subjects: someSubjects phases: somePhases [
	"Subjects from most to least specific, phases from most to least important."

	^ self new
		  setSubjects: someSubjects asArray phases: somePhases asArray;
		  yourself
]

{ #category : 'accessing' }
SBEvent >> keys [

	^ self keysExpandingSubjectsWith: Dictionary new
]

{ #category : 'accessing' }
SBEvent >> keysExpandingSubjectsWith: setsBySubject [
	"The bank keys to look up, in order: for each phase, most important first, every subject from most to least specific, each followed by the sets (from setsBySubject) that contain it. Without phases, the subjects are the keys."

	| expanded |
	expanded := subjects flatCollect: [ :subject | { subject } , (setsBySubject at: subject ifAbsent: [ #(  ) ]) ].
	phases ifEmpty: [ ^ expanded asArray ].
	^ Array streamContents: [ :stream | phases do: [ :phase | expanded do: [ :subject | stream nextPut: subject , '.' , phase ] ] ]
]

{ #category : 'accessing' }
SBEvent >> name [

	^ self keys first
]

{ #category : 'accessing' }
SBEvent >> phases [

	^ phases
]

{ #category : 'printing' }
SBEvent >> printOn: aStream [

	super printOn: aStream.
	aStream
		nextPut: $(;
		nextPutAll: self name;
		nextPut: $)
]

{ #category : 'initialization' }
SBEvent >> setSubjects: someSubjects phases: somePhases [

	subjects := someSubjects.
	phases := somePhases
]

{ #category : 'accessing' }
SBEvent >> subjects [

	^ subjects
]
