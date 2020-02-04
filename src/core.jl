import Base: match, replace

export match


const Σ = Symbol
>ₑ(a, b) = a > b
>ₑ(a::Function, b::Function) = a.uid > b.uid


abstract type AbstractTheory end
abstract type AbstractTerm end
abstract type AbstractMatcher end
abstract type AbstractSubproblem end
abstract type AbstractRewriter end


include("domain.jl")
include("slot.jl")
include("variable.jl")
include("match.jl")
include("rewriter.jl")
