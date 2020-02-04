export Slot


mutable struct Slot end

Base.show(io::IO, x::Slot) = print(io, "Slot(#=", objectid(x), "=#)")


Base.convert(::Type{Expr}, x::Slot) = x

vars(x::Slot) = Set([x])
matcher(x::Slot, V) = (x, push!(copy(V), x))
@inline function match!(σ, x::Slot, t::AbstractTerm)
    if haskey(σ, x)
        σ[x] == t || return nothing
    else
        σ[x] = t
    end
    return EmptySubproblem()
end
replace(x::Slot, σ) = σ[x]

>ₜ(::Slot, ::AbstractTerm) = false
>ₜ(::AbstractTerm, ::Slot) = true
>ₜ(x::Slot, y::Slot) = objectid(x) > objectid(y)

function compile(x::Slot, V)
    fn_name = gensym(:match!_var)
    empty = EmptySubproblem()
    body = if x ∈ V
        :(σ[$x] == t ? $empty : nothing)
    else
        quote
            if haskey(σ, $x)
                σ[$x] == t ? $empty : nothing
            else
                σ[$x] = t
                $empty
            end
        end
    end

    fn_name, Expr(:block, Expr(:function, :($fn_name(σ, t)), body))
end
