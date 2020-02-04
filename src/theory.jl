export @theory!, @term, @rules, @rewrite


const THEORY = Dict{Σ,AbstractTheory}()

macro theory!(theories)
    @assert isa(theories, Expr) && theories.head === :block
    Base.remove_linenums!(theories)

    for line ∈ theories.args
        @assert line.head === :call && line.args[1] === :(=>)
        THEORY[line.args[2]] = Base.eval(__module__, line.args[3])
    end

    nothing
end

function _theory_op(f, args...)
    theory_op(f, map(domain, args)...)
end

function _promote_domain(f, args...)
    promote_domain(f, map(domain, args)...)
end

function _to_term(expr; strict=false, define_vars=false)
    if expr isa Expr && expr.head === :call
        args  = copy(expr.args[2:end])

        for i ∈ eachindex(args)
            args[i] = _to_term(args[i]; strict=strict, define_vars=define_vars)
        end

        eargs = map(esc, args)
        th    = :(_theory_op($(eargs...)))
        dmn   = :(_promote_domain($(eargs...)))

        :(term($th, $(esc(expr.args[1])), [$(args...)]; domain=$dmn))
    else
        return expr
    end
end


function Base.show(io::IO, t::Union{Variable, AbstractTerm})
    term_expr = convert(Expr, t)
    Base.show_call(io, :call, Symbol("@term"), [term_expr], 0)
end

macro term(expr)
    _to_term(expr; define_vars=true)
end


function _rules_replace!(ex, vars)
    isa(ex, Symbol) && return get(vars, ex, ex)

    if isa(ex, Expr)
        for i ∈ eachindex(ex.args)
            ex.args[i] = _rules_replace!(ex.args[i], vars)
        end
    end
    return ex
end
function _clean(ex, vars)
    ex′ = _rules_replace!(ex, vars)
    _to_theory(THEORY, ex′; strict=true)
end
macro rules(name, varnames, body)
    @assert isa(name, Symbol)
    @assert isa(varnames, Expr) && varnames.head === :vect
    @assert all(isa(x, Symbol) for x ∈ varnames.args)

    @assert isa(body, Expr) && body.head === :block
    Base.remove_linenums!(body)

    vars = Dict(x => Variable() for x ∈ varnames.args)

    rw = Rewriter()
    for i ∈ eachindex(body.args)
        line = body.args[i]
        @assert line.head === :(:=)
        lhs, rhs = _clean.(line.args, Ref(vars))
        push!(rw, lhs => replace(rhs))
    end

    fn, expr = compile(rw)

    struct_name = gensym(name)
    return quote
        $expr
        $(esc(name))(t) = $fn(t)
    end
end


macro rewrite(rw, expr)
    term = _to_term(expr)
    :($(esc(rw))($term))
end
