using OrderedCollections
import Base

"""
    Variables(vars::Vector{Symbol})

An ordered list of variable names — endogenous, exogenous, or parameters. Wraps a
`Vector{Symbol}` and behaves like one; build it with the [`@variables`](@ref) macro
or from an `OrderedDict` of parameters.
"""
struct Variables <: AbstractVector{Symbol}
    variables::Vector{Symbol}
end

Variables(x::OrderedDict) = Variables([k for (k, v) in x])
Variables(x::Variables) = x
Variables() = Variables(Symbol[])

MacroTools.@forward Variables.variables Base.getindex, Base.setindex!, Base.size

macro variables(input...)
    if (length(input) > 0) && (input[1] isa Expr) && (input[1].head == :block)
        @assert (length(input) == 1) "Can't handle several blocks"
        args = input[1].args
        vars = filter(e -> isa(e, Symbol), args)
        return Variables(deepcopy(vars))
    else # convert potential tuple to array
        return Variables(remove_expr([handle_input(input)...]))
    end
end

"""
Macro to specify the parameters. Parameters typically can not change over time and can be calibrated to fit given data.

Returns an OrderedDict.

# Example:
    @parameters begin
        θ = 0.2
        α_1 = 0.6
        α_2 = 0.4
    end
"""
macro parameters(block)
    exprs = block.args

    # Filter for assignments
    assignments = filter(e -> isa(e, Expr) && e.head == :(=), exprs)

    # Extract variable names and their values as symbols with colons
    pairs = [Expr(:call, :(=>), :(Symbol($("$(a.args[1])"))), a.args[2]) for a in assignments]

    return esc(Expr(:call, :(Consistent.OrderedDict), pairs...))
end

"""
    Equations(exprs::Vector{Expr})

An ordered list of model equations. Wraps a `Vector{Expr}` and behaves like one;
build it with the [`@equations`](@ref) macro.
"""
struct Equations <: AbstractVector{Expr}
    exprs::Vector{Expr}
end
MacroTools.@forward Equations.exprs Base.getindex, Base.setindex!, Base.size

# Display equations as readable strings (`Y = C + G`) rather than quoted
# expressions (`:(Y = C + G)`).
function Base.show(io::IO, ::MIME"text/plain", eqs::Equations)
    print(io, length(eqs), "-element Equations:")
    for eq in eqs
        print(io, "\n ", string(eq))
    end
end
Base.show(io::IO, eqs::Equations) = print(io, "Equations([", join(string.(eqs), "; "), "])")

"""
Macro to specify the model equations. Use `begin ... end`.

Lagged variables are written `x[-1]`, `x[-2]`, …. The difference operator `Δ` is
available as sugar: `Δ(x)` expands to `x - x[-1]` and `Δ(x, n)` to `x - x[-n]`.

# Example:
    @equations begin
        Y = G + C
        Δ(H) = G - T   # same as: H - H[-1] = G - T
    end
"""
macro equations(input...)
    # striplines keeps the stored equations free of LineNumberNodes so they print
    # cleanly and compare/hash by content
    ex = remove_blocks(MacroTools.striplines(input...))
    @assert (ex.head == :block) "Block input expected" # we need block input (begin ... end)
    # desugar the difference operator: Δ(x) -> x - x[-1]
    return Equations(map(expand_diff, deepcopy(ex.args)))
end