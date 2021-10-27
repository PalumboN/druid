"
I am a Druid optimisation that implements the SCCP algorithm (Sparce Conditional Constant Propagation) on IR instructions.

I propagate constants in the control flow graph instructions and perform constant folding on the instructions when I determine they operands will be constant.
This reduces the number of useful lines of code and allows a subsequent pass of dead code elimination.

Moreover, I apply constant folding and propagation conditionally: edges in the control flow graph are visited only if I determine that they can be visited at runtime.
On the contrary, if I can statically decide that some edge will never be visited, e.g., if a condition is always false, those edges will never be visited and allow more agressive propagations. 

I am implemented as a two-phase algorithm.
The first phase does an abstract interpretation of the control flow graph and computes the lattice values that correspond to each instruction in the graph.
The second phase replaces
 - each instruction with a constant lattice value by a copy instruction with that value
 - each operand with a constant lattive value by a that value

More information about SCCP algorithm : 
http://www.r-5.org/files/books/computers/compilers/writing/Keith_Cooper_Linda_Torczon-Engineering_a_Compiler-EN.pdf
Section 10.7

[Note]: In the book above, the algorithm is built to optimise control flow graphs that contain only one operation per block (assign or conditionnal).
This is not true for Druid, so some parts of the algorithm had to be changed to take this difference into account. 
The algorithm was also refactored for readability, so there are intermediate methods that are not in the book. 

The CFGEdges are modelled by the DREdge objects. 
The SSAEdges are modelled by the instruction itself, because Druid IR is in SSA form. 
"
Class {
	#name : #DRSCCP,
	#superclass : #Object,
	#instVars : [
		'latticeValues',
		'edges',
		'instancecfg',
		'ssaWorkList',
		'cfgEdgeWorkList'
	],
	#category : #'Druid-Optimizations'
}

{ #category : #executing }
DRSCCP >> addJumpToCFGWorklist: aDRJump [

	"Add to the edge work list the edge corresponding to this jump instruction"
	cfgEdgeWorkList add: (edges detect: [ :e | 
		  e source = aDRJump basicBlock and: [ 
			  e destination = aDRJump target ] ])
]

{ #category : #executing }
DRSCCP >> addToEdgeCFGWorklistConditionalJump: aDRJump targetting: aBasicBlock [

	"Add to the edge work list the edge corresponding to this jump instruction"

	| edge |
	edge := edges detect: [ :e | 
		        e destination = aBasicBlock and: [ 
			        e source = aDRJump basicBlock ] ].
	cfgEdgeWorkList add: edge
]

{ #category : #executing }
DRSCCP >> applyPropagation [

	instancecfg instructions copy do: [ :i |
		"Replace instructions and instruction operands using the computed lattices"
		self applyPropagationToInstruction: i ]
]

{ #category : #executing }
DRSCCP >> applyPropagationToInstruction: i [

	"Replace the operands of instructions by their propagated values on non phi functions"
	self tryReplaceInstructionOperands: i.
	self tryReplaceConditionalJump: i.
	self tryReplaceInstructionByFoldedValue: i
]

{ #category : #executing }
DRSCCP >> applyTo: cfg [


	self initializeSCCPWithCFG: cfg.

	[ cfgEdgeWorkList isEmpty and: [ssaWorkList isEmpty] ] whileFalse: [ 
		self stepCFGEdgeWorklist.
		self stepInstructionWorklist].

	self applyPropagation.
]

{ #category : #lattice }
DRSCCP >> bottom [

	^ 'Bot'
]

{ #category : #initialization }
DRSCCP >> buildEdges: cfg [

	| list workList currentBlock edge|
	
	list := OrderedCollection new. 
	workList := OrderedCollection new. 
	workList add: cfg initialBasicBlock. 
	
	[workList isEmpty] whileFalse: [ 
		currentBlock := workList removeFirst. 
		currentBlock successors do: [ :s | 
			edge := DREdge new. 
			edge source: currentBlock. 
			edge destination: s. 
			list add: edge.
			self haltIf: [ s isNil ].
			workList add: s]].
	
	^ list
]

{ #category : #executing }
DRSCCP >> evaluateInstruction: instruction [

	instruction sccpEvaluateFor: self
]

{ #category : #querying }
DRSCCP >> executedEdgesEntering: aBlock [

	^ edges select: [ :e | e destination = aBlock and: [e isExecuted]].
]

{ #category : #initialization }
DRSCCP >> initialize [

	super initialize.
	latticeValues := Dictionary new.
	ssaWorkList := OrderedCollection new.
	cfgEdgeWorkList := OrderedCollection new.
]

{ #category : #initialization }
DRSCCP >> initializeSCCPWithCFG: cfg [

	instancecfg := cfg.
	
	"This operation marks the edges as unexecuted."
	edges := self buildEdges: cfg.

	"Edges leaving the initial block."
	cfgEdgeWorkList addAll: (edges select: [ :edge | edge source = cfg initialBasicBlock ])
]

{ #category : #executing }
DRSCCP >> isConstantLattice: aLattice [

	| nonConstants |
	nonConstants := { self top. self bottom }.
	^ (nonConstants includes: aLattice) not
]

{ #category : #lattice }
DRSCCP >> latticeValue: aValue [

	"Return the lattice value for the register"
	(aValue isRegister and: [ aValue isVirtualRegister not ])
		ifTrue: [ ^ self bottom ].
	aValue isInstruction ifFalse: [ ^ aValue ].

	^ latticeValues at: aValue result ifAbsent: [ self top ]
]

{ #category : #executing }
DRSCCP >> latticeValueOfPhiFunction: operation [

	| values |

	values := operation operands collect: [ :e | 
		self latticeValue: e ] as: Set.
	values remove: self top ifAbsent: [ "Nothing" ].
	values size = 1 ifTrue: [ ^ values anyOne ].
	^ self bottom
]

{ #category : #lattice }
DRSCCP >> setValueOf: anInstruction at: aValue [

	"Set the new lattice value associated with the instruction.
	Invalidate all its usages so they are recomputed"
	latticeValues at: anInstruction result put: aValue.
	ssaWorkList addAll: (self usesOf: anInstruction)
]

{ #category : #executing }
DRSCCP >> stepCFGEdgeWorklist [

	"Each basic block is visited only once.
	This means that edges are visited only once, and blocks with many predecessors are only visited on their first visit"
	
	| currentEdge edgeList |

	cfgEdgeWorkList isEmpty ifTrue: [ ^ self ].

	currentEdge := cfgEdgeWorkList removeFirst.
	currentEdge isExecuted ifTrue: [ ^ self ].
	
	"Mark the current edge as executed"
	currentEdge mark.

	"If there are more than one edge executed arriving to this block already, this means that we already visited it before.
	Quit"
	edgeList := self executedEdgesEntering: currentEdge destination.
	edgeList size > 1 ifTrue: [ ^ self ].

	currentEdge destination instructionsDo: [ :instruction | 
		self evaluateInstruction: instruction ]
]

{ #category : #executing }
DRSCCP >> stepInstructionWorklist [

	| currentInstruction workingBlock |
	ssaWorkList isEmpty ifTrue: [ ^ self ].

	currentInstruction := ssaWorkList removeFirst.
	workingBlock := currentInstruction basicBlock.
	(self executedEdgesEntering: workingBlock) isEmpty ifFalse: [ 
		self evaluateInstruction: currentInstruction ]
]

{ #category : #lattice }
DRSCCP >> top [

	^ 'Top'
]

{ #category : #executing }
DRSCCP >> tryReplaceConditionalJump: i [

	| constantTarget |
	(i isConditionalJump and: [ i condition isConstant ]) ifFalse: [ ^ self ].
	
	constantTarget := i condition value
		                  ifTrue: [ i trueBranch ]
		                  ifFalse: [ i falseBranch ].
	i replaceBy: (DRJump new target: constantTarget)
]

{ #category : #executing }
DRSCCP >> tryReplaceInstructionByFoldedValue: i [

	| lattice replacement |
	"Only replace if the instruction is not a jump"
	i isJump ifTrue: [ ^ self ].

	lattice := self latticeValue: i.
	(self isConstantLattice: lattice) ifFalse: [ ^ self ].

	replacement := DRCopy
		               operands: { lattice asDRValue }
		               result: i result.
	i users do: [ :e | e replaceOperand: i by: replacement ].
	i basicBlock replaceInstruction: i by: replacement.
	
]

{ #category : #executing }
DRSCCP >> tryReplaceInstructionOperands: i [

	i isPhiFunction ifFalse: [ "Replace the operands of instructions by their propagated values on non phi functions"
		i operands withIndexDo: [ :operand :index | 
			| lattice |
			lattice := self latticeValue: operand.
			(self isConstantLattice: lattice) ifTrue: [ 
				i operandAt: index put: lattice asDRValue ] ] ]
]

{ #category : #querying }
DRSCCP >> usesOf: anInstruction [
	
	| ret |

	anInstruction isConditionalJump ifTrue: [
		self value = self top ifTrue: [ 
			ret := OrderedCollection new. 
			ret addAll: anInstruction trueBranch instructions.
			ret addAll: anInstruction falseBranch instructions. 
			^ ret ]
		ifFalse: [ 
			"We assume self value = self bottom" 
			anInstruction condition value ifTrue: [ 
				 ret := OrderedCollection new. 
				 ret addAll: anInstruction trueBranch instructions.
				^ ret. ]
			ifFalse: [ 
				ret := OrderedCollection new. 
				ret addAll: anInstruction falseBranch instructions.
				^ ret. ] ] ]. 
	^ instancecfg instructions select: [ :instruction | 
		  instruction operands includes: anInstruction ]
]