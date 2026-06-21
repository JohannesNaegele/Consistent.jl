# Structural analysis of a model: equality up to ordering, the within-period
# dependency structure, and a canonical block-triangular reordering.

"""
Two models are equal if they have the same endogenous/exogenous/parameter
variables and the same equations, *regardless of the order* in which they were
written or combined. In particular `a + b == b + a`.
"""
function Base.:(==)(a::Model, b::Model)
    return Set(a.endogenous_variables) == Set(b.endogenous_variables) &&
           Set(a.exogenous_variables) == Set(b.exogenous_variables) &&
           Set(a.parameters) == Set(b.parameters) &&
           Set(a.equations.exprs) == Set(b.equations.exprs)
end

function Base.hash(m::Model, h::UInt)
    h = hash(Set(m.endogenous_variables), h)
    h = hash(Set(m.exogenous_variables), h)
    h = hash(Set(m.parameters), h)
    h = hash(Set(m.equations.exprs), h)
    return h
end

"""
Collect the endogenous variables referenced at the *current* period in an
expression. Lagged references (`x[-1]`, …) are predetermined and ignored.
"""
function current_period_vars(x, endos::Set{Symbol}, acc::Set{Symbol}=Set{Symbol}())
    if x isa Symbol
        x in endos && push!(acc, x)
    elseif x isa Expr
        if x.head === :ref
            var = x.args[1]
            idx = length(x.args) >= 2 ? x.args[2] : 0
            # only the current period (bare or `[0]`) creates a same-period dependency
            if var isa Symbol && var in endos && idx == 0
                push!(acc, var)
            end
        else
            for a in x.args
                current_period_vars(a, endos, acc)
            end
        end
    end
    return acc
end

"""
    block_decomposition(model) -> Vector{Vector{Symbol}}

Decompose the model into blocks based on within-period dependencies (lagged
variables are predetermined, so they do not couple the system). Each block is a
set of endogenous variables that must be solved simultaneously; the blocks are
returned in an order in which they can be solved one after another — every block
depends only on itself and on earlier blocks.

The decomposition is canonical: it depends only on the equations, not on the
order in which variables or equations were written, so combining models in either
order yields the same decomposition.
"""
function block_decomposition(m::Model)
    endos = collect(m.endogenous_variables)
    endoset = Set(endos)
    lhs = left_symbol.(m.equations.exprs)
    eq_of = Dict(lhs[i] => m.equations.exprs[i] for i in eachindex(lhs))

    adj = Dict{Symbol, Vector{Symbol}}()
    for v in endos
        deps = current_period_vars(eq_of[v], endoset)
        delete!(deps, v) # a variable does not depend on itself
        adj[v] = sort!(collect(deps), by=string)
    end

    return _tarjan_scc(sort(endos, by=string), adj)
end

# Tarjan's strongly-connected-components algorithm. With edges `u -> v` meaning
# "u depends on v", components are emitted with sinks (depend on nothing else)
# first, which is exactly the order in which the blocks can be solved.
# Nodes and adjacency are iterated in sorted order so the output is deterministic.
function _tarjan_scc(nodes::Vector{Symbol}, adj::Dict{Symbol, Vector{Symbol}})
    index = Dict{Symbol, Int}()
    lowlink = Dict{Symbol, Int}()
    onstack = Set{Symbol}()
    stack = Symbol[]
    counter = Ref(0)
    sccs = Vector{Vector{Symbol}}()

    function strongconnect(v)
        index[v] = counter[]
        lowlink[v] = counter[]
        counter[] += 1
        push!(stack, v)
        push!(onstack, v)
        for w in adj[v]
            if !haskey(index, w)
                strongconnect(w)
                lowlink[v] = min(lowlink[v], lowlink[w])
            elseif w in onstack
                lowlink[v] = min(lowlink[v], index[w])
            end
        end
        if lowlink[v] == index[v]
            comp = Symbol[]
            while true
                w = pop!(stack)
                delete!(onstack, w)
                push!(comp, w)
                w == v && break
            end
            push!(sccs, sort!(comp, by=string))
        end
    end

    for v in nodes
        haskey(index, v) || strongconnect(v)
    end
    return sccs
end

"""
    reorder(model) -> Model

Return an equivalent model whose endogenous variables and equations are sorted
into canonical block-triangular order (see [`block_decomposition`](@ref)). The
result is `==` to the input but has a deterministic layout independent of how the
model was assembled.
"""
function reorder(m::Model)
    blocks = block_decomposition(m)
    new_order = reduce(vcat, blocks; init=Symbol[])
    lhs = left_symbol.(m.equations.exprs)
    eq_of = Dict(lhs[i] => m.equations.exprs[i] for i in eachindex(lhs))
    new_eqs = [eq_of[v] for v in new_order]
    return model(
        endos = Variables(copy(new_order)),
        exos = m.exogenous_variables,
        params = m.parameters,
        eqs = Equations(new_eqs)
    )
end
