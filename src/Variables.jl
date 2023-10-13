"""
Find all symbols in an array of expressions.
"""
function vars(lines::Vector)
    found::Set{Symbol} = Set([])
    for i in eachindex(lines)
        union!(found, find_symbols(lines[i]))
    end
    return found
end

"""
Convert all variables in an expression like x to x[0] (vector representation for time 0).
"""
function create_missing_indices(line::Expr, vars::Set, symbs::Set)
    not_symbs = Symbol[]
    completed_line = deepcopy(line)
    head = completed_line.head
    args = completed_line.args
    for i in length(args):-1:2 # FIXME: why?
        if (typeof(args[i]) == Symbol) && (head == :call) && args[i] in vars # create index
            args[i] = :($(args[i])[0])
        elseif typeof(args[i]) == Expr # recursion for nested expressions
            args[i] = create_missing_indices(args[i], vars, symbs)
        elseif (typeof(args[i]) == Symbol) && # handle undeclared variables
               (head == :call) &&
               !(args[i] in symbs) &&
               !(args[i] in not_symbs)
            push!(not_symbs, args[i])
        end
    end
    # gets printed for every equation in which symbols appears (could be enhanced)
    if length(not_symbs) > 0
        @warn "Symbols $(not_symbs[1:end]) are not in variables or parameters"
    end
    return completed_line
end

"""
Replace variables with their vector (matrix) representation.
"""
function create_vars( # FIXME: read properly
    line::Expr,
    vars::Set,
    endos::Array,
    exos::Array,
    name = [:endos, :lags, :exos]
)
    completed_line = deepcopy(line)
    head = line.head
    args = line.args
    # we expect every variable to be associated with an index!
    if head == :ref
        # catch unknown symbol
        if args[1] in vars
            # handle endogenous variables
            if args[1] in endos
                position = findall(x -> x == args[1], endos)[1]
                if length(args) == 2
                    if args[2] == 0
                        completed_line.args = [name[1], :($position)]
                    else
                        if args[2] < 0
                            completed_line.args = [name[2], :($position), Expr(:call, :-, :end, args[2] + 1)]
                        else
                            error("future indices are not allowed!")
                        end
                    end
                else
                    error("$(args[2:end]) is not a valid index!")
                end
            # handle exogenous variables
            else
                position = findall(x -> x == args[1], exos)[1]
                if length(args) == 2
                    if args[2] <= 0
                        completed_line.args = [name[3], :($position), Expr(:call, :-, :end, args[2])]
                    else
                        error("future indices are not allowed!")
                    end
                else
                    error("$(args[2:end]) is not a valid index!")
                end
            end
        else
            error("$(args[1]) is not a variable!")
        end
    else
        for i in eachindex(args)
            if typeof(args[i]) == Expr
                completed_line.args[i] = create_vars(line.args[i], vars, endos, exos, name)
            end
        end
    end
    return completed_line
end

"""
Replace symbols which are used as parameters with their individual index params[i] for the function input params.
"""
function create_params(line::Expr, params::Array, name = :params)
    completed_line = deepcopy(line)
    args = line.args
    for i in eachindex(args)
        if typeof(args[i]) == Symbol && args[i] in params # check whether we found parameter
            position = findall(x -> x == args[i], params)[1]
            completed_line.args[i] = :($(name)[$(position)]) # replace with vector input
        elseif typeof(args[i]) == Expr # recursion for nested expressions
            completed_line.args[i] = create_params(args[i], params, name)
        end
    end
    return completed_line
end

"""
Replace the symbols for variables and parameters with the inputs used in the function.

# Example:

```julia-repl
julia> replace_vars([:(α * G + Y - Y[-2])], [:Y], [:G], [:α])
1-element Vector{Expr}:
 :((params[1] * exos[1, 1] + endos[1]) - lags[1, 2])
```
"""
function replace_vars(
    lines::Vector,
    endos::Vector{Symbol},
    exos::Vector{Symbol},
    params::Vector{Symbol},
    name=[:endos, :lags, :exos, :params],
)
    vars = union(Set(endos), Set(exos))
    symbs = union(vars, Set(params), math_operators)
    replaced = deepcopy(lines)
    for i in eachindex(lines)
        replaced[i] = create_missing_indices(replaced[i], vars, symbs)
        replaced[i] = create_vars(replaced[i], vars, endos, exos, name[1:3])
        replaced[i] = create_params(replaced[i], params, name[4])
    end
    return replaced
end