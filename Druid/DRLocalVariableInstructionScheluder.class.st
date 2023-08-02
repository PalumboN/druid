Class {
	#name : #DRLocalVariableInstructionScheluder,
	#superclass : #DROptimisation,
	#category : #'Druid-BytecodeGeneration'
}

{ #category : #operations }
DRLocalVariableInstructionScheluder >> applyTo: cfg [

	cfg instructionsDo: [ :i |
		(self shouldIgnore: i) ifFalse: [
			i users size > 1 ifTrue: [ self storeReusedResultOf: i ] ].

		(i isPhiFunction and: [ i hasRecursiveUse not ]) ifTrue: [
			self storePhiFunctionOperands: i ] ]
]

{ #category : #operations }
DRLocalVariableInstructionScheluder >> shouldIgnore: aDRInstruction [

	^ aDRInstruction isStore or: [
		  aDRInstruction isPhiFunction and: [
			  aDRInstruction operands allSatisfy: [ :op | op isStore ] ] ]
]

{ #category : #tranformation }
DRLocalVariableInstructionScheluder >> storePhiFunctionOperands: aDRPhiFunction [

	aDRPhiFunction operands copy do: [ :op |
		op class = DRInterpreterValue ifTrue: [
			| pred |
			pred := aDRPhiFunction predecessorAtOperand: op.
			aDRPhiFunction replaceOperand: op by: (pred copy: op) ] ].

	aDRPhiFunction operands do: [ :op |
		op basicBlock
			add: (DRStoreTemporaryVariable
					 operands: {
							 aDRPhiFunction result name asLowercase asDRValue.
							 op }
					 result: DRNoRegister new)
			after: op ].


	aDRPhiFunction replaceBy:
		(DRLoadTemporaryVariable operands: { aDRPhiFunction result name asLowercase asDRValue })
]

{ #category : #transformation }
DRLocalVariableInstructionScheluder >> storeReusedResultOf: aDRInstruction [

	| store |
	self assert: aDRInstruction result isRegister.

	aDRInstruction replaceUsesBy: (DRLoadTemporaryVariable operands: {
				 aDRInstruction result name asLowercase asDRValue.
				 "store" }).

	aDRInstruction basicBlock
		add: (DRStoreTemporaryVariable
				 operands: {
						 aDRInstruction result name asLowercase asDRValue.
						 aDRInstruction }
				 result: DRNoRegister new)
		after: aDRInstruction
]
