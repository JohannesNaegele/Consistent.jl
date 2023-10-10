using MacroTools

"""
Some variable names are interpreted as operators.
Thus, we decompose expressions like :(a in b) in individual Symbols.
"""
function remove_expr(x::Expr)
    if x.head == :call
        return [x.args[2], x.args[1], x.args[3]]
    else
        error("Can not handle $x")
    end
end

"""
We expect an array of variable names; some however form an Expr instead of being individual Symbols.
"""
function remove_expr(x::Array)
    # we need a deepcopy to avoid issues with recursive changes
    untangled = deepcopy(x)
    for i in eachindex(x)[end:begin]
        if typeof(untangled[i]) == Expr
            untangled = [
                untangled[1:(i-1)];
                remove_expr(untangled[i]);
                untangled[(i+1):end]
            ]
        end
    end
    return untangled
end

remove_blocks(e::Any) = e

"""
Sometimes our equation input might have lines which are themselves blocks (with only a single line).
This happens e.g. if we have two variables on the left hand side.
In such a case we just want to convert this block into it's contents.
"""
function remove_blocks(expr::Expr)
    for (i, arg) in enumerate(expr.args)
        if typeof(arg) == Expr
            if arg.head == :block
                if (length(arg.args) == 1)
                    expr.args[i] = remove_blocks(arg.args[1])
                else
                    error("Can not handle sub-blocks with multiple lines.")
                end
            else
                expr.args[i] = remove_blocks(arg)
            end
        end
    end
    return expr
end

"""
Find all symbols in an Expr aside from the math operators.
"""
function find_symbols(line::Expr)
    found::Set{Symbol} = Set([])
    args = line.args
    for i in eachindex(args)
        if typeof(args[i]) == Symbol
            push!(found, args[i])
        elseif typeof(args[i]) == Expr
            union!(found, find_symbols(args[i]))
        end
    end
    return setdiff(found, math_operators)
end