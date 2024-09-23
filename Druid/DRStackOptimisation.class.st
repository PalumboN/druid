Class {
	#name : #DRStackOptimisation,
	#superclass : #DROptimisation,
	#category : #'Druid-Optimizations'
}

{ #category : #accessing }
DRStackOptimisation >> applyTo: cfg [

	cfg rebuildStackDependencies.
	self doApply: cfg.
	cfg rebuildStackDependencies. "Before and after?"

]

{ #category : #accessing }
DRStackOptimisation >> doApply: cfg [

	self subclassResponsibility
]