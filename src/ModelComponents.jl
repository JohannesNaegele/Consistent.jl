using OrderedCollections
import Base

# Wrapper for vector of symbols
struct Variables <: AbstractVector{Symbol}
    variables::Vector{Symbol} # TODO: add documentation for variables
end

Variables(x::OrderedDict) = Variables([k for (k, v) in x])
Variables(x::Variables) = x
Variables() = Variables(Symbol[])

MacroTools.@forward Variables.variables Base.getindex, Base.setindex!
Base.size(x::Variables) = Base.size(x.variables)

macro variables(input...)
    if (input[1] isa Expr) && (input[1].head == :block)
        @assert (length(input) == 1) "Can't handle several blocks"
        args = input[1].args
        vars = filter(e -> isa(e, Symbol), args)
        return Variables(deepcopy(vars))
    else # convert potential tuple to array
        return Variables(remove_expr([handle_input(input)...]))
    end
end

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