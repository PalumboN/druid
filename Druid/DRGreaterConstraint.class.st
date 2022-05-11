Class {
	#name : #DRGreaterConstraint,
	#superclass : #DRRangedConstraint,
	#category : #'Druid-Optimizations'
}

{ #category : #arithmetic }
DRGreaterConstraint >> hasAllValuesGreaterThan: otherConstantValue [

	^ otherConstantValue >= constantValue 
]

{ #category : #arithmetic }
DRGreaterConstraint >> hasAllValuesLessThan: aConstantValue [

	^ false
]

{ #category : #arithmetic }
DRGreaterConstraint >> hasValue: otherConstantValue [

	^ otherConstantValue > constantValue
]

{ #category : #arithmetic }
DRGreaterConstraint >> isIncludedIn: otherConstraint [

	^ otherConstraint hasAllValuesGreaterThan: constantValue
]

{ #category : #arithmetic }
DRGreaterConstraint >> negated [

	^ DRLessOrEqualsConstraint withValue: constantValue
]

{ #category : #printing }
DRGreaterConstraint >> opCode [

	^ '>'
]