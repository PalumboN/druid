Class {
	#name : #DRSCCPConstantPropagationTest,
	#superclass : #DRSCCPTest,
	#category : #'Druid-Tests'
}

{ #category : #tests }
DRSCCPConstantPropagationTest >> testDoNotPropagateInPhiFunctions [

	"Phi functions should contain variables and not values"

	| cfg copy1 b1 b2 b3 copy2 joinBlock phi |
	cfg := DRControlFlowGraph new.
	cfg initialBasicBlock: DRBasicBlock new.
	
	cfg initialBasicBlock jumpTo: (b1 := DRBasicBlock new).
	b1 endInstruction: (instructionFactory jumpIf: (DRPhysicalRegister name: 'Parameter')).

	"T1 := 1"
	b1 endInstruction trueBranch: (b2 := DRBasicBlock new).
	b2 addInstruction: (copy1 := instructionFactory copy: 1).
	
	"T2 := 2"
	b1 endInstruction falseBranch: (b3 := DRBasicBlock new).
	b3 addInstruction: (copy2 := instructionFactory copy: 2).
	
	joinBlock := DRBasicBlock new.
	b2 jumpTo: joinBlock.
	b3 jumpTo: joinBlock.
	joinBlock addInstruction: (phi := instructionFactory phiWith: copy1 with: copy2).
	
	optimisation applyTo: cfg.

	self assert: phi operand1 equals: copy1.
	self assert: phi operand2 equals: copy2.
]

{ #category : #tests }
DRSCCPConstantPropagationTest >> testPropagateBetweenBasicBlocks [

	| cfg copy1 |
	cfg := self setUpCFG: 3. 

	"T1 := 1"
	cfg b1 addInstruction: (copy1 := instructionFactory copy: 1).
	
	"T2 := T1"
	cfg b2 addInstruction: (instructionFactory copy: copy1).
	
	optimisation applyTo: cfg.

	"The T1 access got replaced by the constant 1"
	self assert: cfg instructions allButLast last operand1 equals: 1 asDRValue
]

{ #category : #tests }
DRSCCPConstantPropagationTest >> testPropagateToAddOperand [

	| cfg copy1 |
	cfg := self setUpCFG: 2.
		
	"T1 := 1"
	cfg b1 addInstruction: (copy1 := instructionFactory copy: 1).
	
	"T2 := Param + T1"
	cfg b1 addInstruction: (instructionFactory add: (DRPhysicalRegister name: 'Rx') to: copy1).
	
	optimisation applyTo: cfg.
	
	"Assert that we propagated the constant to the ADD operand"
	self assert: cfg instructions allButLast last isAdd.
	self assert: cfg instructions allButLast last operand2 equals: 1 asDRValue
]

{ #category : #tests }
DRSCCPConstantPropagationTest >> testPropagateToCopyOperand [

	| cfg copy1 |
	cfg := self setUpCFG: 2. 

	"T1 := 1"
	cfg b1 addInstruction: (copy1 := instructionFactory copy: 1).
	"T2 := T1"
	cfg b1 addInstruction: (instructionFactory copy: copy1).
	
	optimisation applyTo: cfg.

	"The T1 access got replaced by the constant 1"
	self assert: cfg instructions allButLast last operand1 equals: 1 asDRValue
]