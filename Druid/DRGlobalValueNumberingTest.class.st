Class {
	#name : #DRGlobalValueNumberingTest,
	#superclass : #DROptimisationTest,
	#category : #'Druid-Tests'
}

{ #category : #tests }
DRGlobalValueNumberingTest >> testCommutativeOperationIsReplacedByPreviousInstance [
	"This test asserts whether or not equivalent operations are correctly identified and replaced by the optimisation"
			
	| cfg instructionFactory copy3 copy4 firstAddition secondAddition optimisation |
	instructionFactory := DRInstructionFactory new.
	optimisation := DRGlobalValueNumbering new.
	cfg := self setUpCFG: 1.
	cfg b1 addInstruction: (copy3 := instructionFactory copy: 3).
	cfg b1 addInstruction: (copy4 := instructionFactory copy: 4).
	cfg b1 addInstruction: (firstAddition := instructionFactory add: copy3 to: copy4).
	cfg b1 addInstruction: (secondAddition := instructionFactory add: copy4 to: copy3).
	optimisation applyTo: cfg.
	self assert: (cfg b1 instructions includes: secondAddition) not.
	
	
]

{ #category : #tests }
DRGlobalValueNumberingTest >> testComplexEquivalentOperationIsReplacedByPreviousInstance [
	"This test asserts whether or not equivalent operations are correctly identified and replaced by the optimisation"
			
	| cfg instructionFactory copy0 copy2 constant2 firstAddition secondAddition optimisation |
	instructionFactory := DRInstructionFactory new.
	optimisation := DRGlobalValueNumbering new.
	cfg := self setUpCFG: 1.
	cfg b1 addInstruction: (copy0 := instructionFactory copy: 0).
	constant2 := DRConstantValue new;
   value: 2.
	cfg b1 addInstruction: (firstAddition := instructionFactory add: copy0 to: constant2).
	cfg b1 addInstruction: (copy2 := instructionFactory copy: 2).
	cfg b1 addInstruction: (secondAddition := instructionFactory add: copy0 to: copy2).
	optimisation applyTo: cfg.
	self assert: (cfg b1 instructions includes: secondAddition) not.
	
	
]

{ #category : #tests }
DRGlobalValueNumberingTest >> testEquivalentOperationIsNotReplacedWhenBranchesMerge [
	"This test asserts whether operations in different branches are scoped differently"
			
	| cfg instructionFactory jump copy3 copy4 copy5 phi1 phi2 phi3 phi4 optimisation |
	instructionFactory := DRInstructionFactory new.
	optimisation := DRGlobalValueNumbering new.
	jump := DRConditionalJump operands: { DRConstantValue value: true }.
	cfg := self setUpCFGWithConditional: jump.
	cfg b2 addInstruction: (copy3 := instructionFactory copy: 3).
	cfg b2 addInstruction: (copy4 := instructionFactory copy: 4).
	cfg b3 addInstruction: (copy5 := instructionFactory copy: 5).
	cfg b4 addInstruction: (phi1 := instructionFactory phiWith: copy3 with: copy3).
	cfg b4 addInstruction: (phi2 := instructionFactory phiWith: copy3 with: copy4).
	cfg b4 addInstruction: (phi3 := instructionFactory phiWith: copy3 with: copy5).
	cfg b4 addInstruction: (phi4 := instructionFactory phiWith: copy3 with: copy5).
	optimisation applyTo: cfg.
	self assert: (cfg b4 instructions includes: phi1) not.
	self assert: (cfg b4 instructions includes: phi2).
	self assert: (cfg b4 instructions includes: phi3) not.
	self assert: (cfg b4 instructions includes: phi4).
	
]

{ #category : #tests }
DRGlobalValueNumberingTest >> testEquivalentOperationIsNotReplacedWhenBranchesSplit [
	"This test asserts whether operations in different branches are scoped differently"
			
	| cfg instructionFactory jump copy3 copy4 firstAddition secondAddition optimisation |
	instructionFactory := DRInstructionFactory new.
	optimisation := DRGlobalValueNumbering new.
	jump := DRConditionalJump operands: { DRConstantValue value: true }.
	cfg := self setUpCFGWithConditional: jump.
	cfg b1 addInstruction: (copy3 := instructionFactory copy: 3).
	cfg b1 addInstruction: (copy4 := instructionFactory copy: 4).
	cfg b2 addInstruction: (firstAddition := instructionFactory add: copy3 to: copy4).
	cfg b3 addInstruction: (secondAddition := instructionFactory add: copy3 to: copy4).
	optimisation applyTo: cfg.
	self assert: (cfg b2 instructions includes: firstAddition).
	self assert: (cfg b3 instructions includes: secondAddition).
	
	
]

{ #category : #tests }
DRGlobalValueNumberingTest >> testEquivalentOperationIsReplacedByPreviousInstance [
	"This test asserts whether or not equivalent operations are correctly identified and replaced by the optimisation"
			
	| cfg instructionFactory copy3 copy4 firstAddition secondAddition optimisation |
	instructionFactory := DRInstructionFactory new.
	optimisation := DRGlobalValueNumbering new.
	cfg := self setUpCFG: 1.
	cfg b1 addInstruction: (copy3 := instructionFactory copy: 3).
	cfg b1 addInstruction: (copy4 := instructionFactory copy: 4).
	cfg b1 addInstruction: (firstAddition := instructionFactory add: copy3 to: copy4).
	cfg b1 addInstruction: (secondAddition := instructionFactory add: copy3 to: copy4).
	optimisation applyTo: cfg.
	self assert: (cfg b1 instructions includes: secondAddition) not.
	
	
]

{ #category : #tests }
DRGlobalValueNumberingTest >> testNonEquivalentOperationIsNotReplaced [
	"This test asserts whether or not non equivalent operations are left alone by the optimisation"
			
	| cfg instructionFactory copy3 copy4 copy5 firstAddition secondAddition optimisation |
	instructionFactory := DRInstructionFactory new.
	optimisation := DRGlobalValueNumbering new.
	cfg := self setUpCFG: 1.
	cfg b1 addInstruction: (copy3 := instructionFactory copy: 3).
	cfg b1 addInstruction: (copy4 := instructionFactory copy: 4).
	cfg b1 addInstruction: (copy5 := instructionFactory copy: 5).
	cfg b1 addInstruction: (firstAddition := instructionFactory add: copy3 to: copy4).
	cfg b1 addInstruction: (secondAddition := instructionFactory add: copy3 to: copy5).
	optimisation applyTo: cfg.
	self assert: (cfg b1 instructions includes: firstAddition).
	self assert: (cfg b1 instructions includes: secondAddition).
	
	
]