using OrderedCollections
import Base

# Wrapper for vector of symbols
struct Variables <: AbstractVector{Symbol}
    variables::Vector{Symbol} # TODO: add documentation for variables
end

Variables(x::OrderedDict) = Variables([k for (k, v) in x])
Variables(x::Variables) = x

MacroTools.@forward Variables.variables Base.getindex, Base.setindex!
Base.size(x::Variables) = Base.size(x.variables)

struct Equations
    expr::Expr
end

macro parameters(block)
    exprs = block.args

    # Filter for assignments
    assignments = filter(e -> isa(e, Expr) && e.head == :(=), exprs)

    # Extract variable names and their values as symbols with colons
    pairs = [Expr(:call, :(=>), :(Symbol($("$(a.args[1])"))), a.args[2]) for a in assignments]

    return esc(Expr(:call, :OrderedDict, pairs...))
end