"
I load SoundBank: Wwise-style sound banks for Pharo. A bank maps event keys to sound nodes (random, sequence, and layer containers with pitch, volume, and delay randomizers), and an engine plays posted events on a SuperCollider server through Scsynth.

	Metacello new
		githubUser: 'Gabriel-Darbord' project: 'SoundBank' commitish: 'main' path: 'src';
		baseline: 'SoundBank';
		load.

Groups: Core, Tests, and default (both). Depends on Scsynth.
"
Class {
	#name : 'BaselineOfSoundBank',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfSoundBank',
	#package : 'BaselineOfSoundBank'
}

{ #category : 'baselines' }
BaselineOfSoundBank >> baseline: spec [

	<baseline>
	spec for: #common do: [
			self defineDependencies: spec.
			self definePackages: spec.
			self defineGroups: spec ]
]

{ #category : 'baselines' }
BaselineOfSoundBank >> defineDependencies: spec [

	spec baseline: 'Scsynth' with: [
			spec
				repository: 'github://Gabriel-Darbord/Scsynth:main/src';
				loads: #( 'Core' ) ]
]

{ #category : 'baselines' }
BaselineOfSoundBank >> defineGroups: spec [

	spec
		group: 'Core' with: #( 'SoundBank' );
		group: 'Tests' with: #( 'SoundBank-Tests' );
		group: 'default' with: #( 'Core' 'Tests' )
]

{ #category : 'baselines' }
BaselineOfSoundBank >> definePackages: spec [

	spec
		package: 'SoundBank' with: [ spec requires: #( 'Scsynth' ) ];
		package: 'SoundBank-Tests' with: [ spec requires: #( 'SoundBank' ) ]
]
