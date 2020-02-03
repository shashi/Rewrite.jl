abstract type AbstractDomain end
"""
    domain(t)
A representation of the domain of a term
"""
domain(x::AbstractTerm) = Any
domain(x) = typeof(x) # For types outside of Rewrite

"""
    promote domain given an operation on several terms
"""
promote_domain(f, xs...) = Any
