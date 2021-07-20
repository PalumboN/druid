Class {
	#name : #DRControlFlowGraph,
	#superclass : #Object,
	#instVars : [
		'initialBasicBlock'
	],
	#category : #'Druid-IR'
}

{ #category : #iterating }
DRControlFlowGraph >> blocks [

	"Return the list of blocks based on a simple linearization algorithm"

	| blocks |
	blocks := OrderedCollection new.
	self blocksDo: [ :b | blocks add: b ].
	^ blocks
]

{ #category : #iterating }
DRControlFlowGraph >> blocksDo: aFullBlockClosure [ 

	| workingQueue visited visitsSoFar |
	visited := Dictionary new.
	
	
	workingQueue := OrderedCollection new.
	workingQueue add: initialBasicBlock.
	
	[ workingQueue isEmpty ] whileFalse: [ | currentBlock |
		currentBlock := workingQueue removeFirst.
		aFullBlockClosure value: currentBlock.
		currentBlock hasFinalInstruction ifTrue: [
			currentBlock lastInstruction targets do: [ :target |
				
				"Count how many times we have visited this block"
				visitsSoFar := visited
					at: target
					ifPresent: [ :p | p + 1 ]
					ifAbsent: [ 1 ].
				visited at: target put: visitsSoFar.
				
				visitsSoFar = target numberOfPredecessors ifTrue: [ 
					workingQueue addLast: target  ] ] ] ]
]

{ #category : #accessing }
DRControlFlowGraph >> exitBasicBlock [
	
	^ exitBasicBlock
]

{ #category : #accessing }
DRControlFlowGraph >> initialBasicBlock [ 
	^ initialBasicBlock
]

{ #category : #accessing }
DRControlFlowGraph >> initialBasicBlock: aDRBasicBlock [ 
	initialBasicBlock := aDRBasicBlock
]

{ #category : #accessing }
DRControlFlowGraph >> instructions [
	
	| instructions |
	instructions := OrderedCollection new.
	self instructionsDo: [ :e |
		instructions add: e ].
	^ instructions
]

{ #category : #iterating }
DRControlFlowGraph >> instructionsDo: aFullBlockClosure [ 

	| worklist visited |
	visited := Set new.
	worklist := OrderedCollection new.
	worklist add: initialBasicBlock.
	
	[ worklist isEmpty ] whileFalse: [ | currentBlock |
		currentBlock := worklist removeFirst.
		currentBlock instructionsDo: [ :e |
			aFullBlockClosure value: e.
			e targets do: [ :target |
				1haltIf: [ target isNil ].
				(visited includes: target) ifFalse: [ 
					worklist add: target.
					visited add: target ] ] ] ]
]

{ #category : #validating }
DRControlFlowGraph >> validate [
	
	| visited workqueue |
	visited := Set new.
	workqueue := OrderedCollection new.
	workqueue add: initialBasicBlock.
	
	[ workqueue isEmpty ] whileFalse: [ | nextBlock |
		nextBlock := workqueue removeFirst.
		visited add: nextBlock.
		self validateBlock: nextBlock.
		nextBlock successors do: [ :e |
			(visited includes: e)
				ifFalse: [ workqueue add: e ] ] ]
]

{ #category : #validating }
DRControlFlowGraph >> validateBlock: aDRBasicBlock [ 
	
	aDRBasicBlock predecessors do: [ :e |
		(e successors includes: aDRBasicBlock)
			ifFalse: [ self error: 'Predecessor-successor mismatch' ] ].
		
	aDRBasicBlock successors do: [ :e |
		(e predecessors includes: aDRBasicBlock)
			ifFalse: [ self error: 'Predecessor-successor mismatch' ] ].
]