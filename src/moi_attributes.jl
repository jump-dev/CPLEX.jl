# TODO: solver-independent parameters

# TODO: supports modify objective

struct SupportsConicThroughQuadratic <: AbstractSolverAttribute end
struct ObjectiveBound <: AbstractSolverInstanceAttribute end
struct RelativeGap <: AbstractSolverInstanceAttribute  end
struct SolveTime <: AbstractSolverInstanceAttribute end
struct SimplexIterations <: AbstractSolverInstanceAttribute end
struct BarrierIterations <: AbstractSolverInstanceAttribute end
struct NodeCount <: AbstractSolverInstanceAttribute end
struct RawSolver <: AbstractSolverInstanceAttribute end
struct ListOfVariableReferences <: AbstractSolverInstanceAttribute end
struct ListOfConstraintReferences{F,S} <: AbstractSolverInstanceAttribute end
struct ListOfConstraints <: AbstractSolverInstanceAttribute end
struct VariablePrimalStart <: AbstractVariableAttribute end
struct VariableBasisStatus <: AbstractVariableAttribute end
struct ConstraintPrimalStart <: AbstractConstraintAttribute end
struct ConstraintDualStart <: AbstractConstraintAttribute end
struct ConstraintBasisStatus <: AbstractConstraintAttribute end
# struct ConstraintFunction <: AbstractConstraintAttribute end
# struct ConstraintSet <: AbstractConstraintAttribute end
