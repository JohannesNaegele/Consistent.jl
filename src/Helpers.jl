using MacroTools

"""
Some variable names are parsed as operators, so a list like `Y, a in b` yields an
`Expr` instead of separate symbols. We recover the individual names: for a binary
infix call `:(a in b)` (`Expr(:call, :in, :a, :b)`) we return `[a, in, b]`, in
source order.
"""
function remove_expr(x::Expr)
    # only a binary infix call (operator + two operands) is expected here
    if x.head == :call && length(x.args) == 3
        return [x.args[2], x.args[1], x.args[3]]
    elseif x.head == :block
        return x.args
    else
        error("Cannot interpret `$x` as a list of variable names.")
    end
end

"""
We expect an array of variable names; some however form an Expr instead of being individual Symbols.
"""
function remove_expr(x::Array)
    # deepcopy so we never mutate the caller's array while splicing
    untangled = deepcopy(x)
    # Iterate back-to-front: expanding entry `i` into several entries shifts the
    # positions after it, so visiting higher indices first keeps the lower (not
    # yet processed) indices aligned with `x`.
    for i in reverse(eachindex(x))
        if untangled[i] isa Expr
            untangled = [
                untangled[1:(i-1)];
                remove_expr(untangled[i]);
                untangled[(i+1):end]
            ]
        end
    end
    return untangled
end

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
                    # `f(x) = rhs` (e.g. `Δ(M) = F`) parses as a function definition
                    # with the rhs wrapped in a block; unwrap it (recursing only if
                    # it is itself an expression).
                    inner = arg.args[1]
                    expr.args[i] = inner isa Expr ? remove_blocks(inner) : inner
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
Find all variable symbols in an `Expr`, ignoring operators and the names of called
functions (e.g. `log` in `log(x)`).
"""
function find_symbols(line::Expr)
    found = Set{Symbol}()
    args = line.args
    # In a call `f(a, b)` (and infix `a + b`) args[1] is the callee, not a
    # variable, so skip it. For every other head (`:ref`, `:(=)`, ...) all args
    # may contain variables. Registered operators/functions are dropped below.
    start = line.head === :call ? 2 : 1
    for i in start:lastindex(args)
        if args[i] isa Symbol
            push!(found, args[i])
        elseif args[i] isa Expr
            union!(found, find_symbols(args[i]))
        end
    end
    return setdiff(found, math_operators)
end

"""
Get the symbol farthest to the left in an `Expr` — the variable an equation
determines. We need not inspect `.head`: the determined variable is simply the
leftmost symbol that is not a registered operator/function (see `math_operators`
and `operators!`). Callables such as `log`/`exp` must be registered, so they are
skipped here just like `+`/`-`.
"""
function left_symbol(line::Expr)
    args = line.args
    for i in eachindex(args)
        if args[i] isa Symbol && !(args[i] in math_operators)
            return args[i]
        elseif args[i] isa Expr
            found = left_symbol(args[i])
            if found isa Symbol
                return found
            end
        end
    end
    # fallback
    return nothing
end

"""
Lag a single (optionally already lagged) variable by `n` periods: `x -> x[-n]`
and `x[-k] -> x[-(k+n)]`.
"""
function _lag(e, n::Integer)
    if e isa Symbol
        return Expr(:ref, e, -n)
    elseif e isa Expr && e.head === :ref && length(e.args) == 2 && e.args[2] isa Integer
        return Expr(:ref, e.args[1], e.args[2] - n)
    else
        error("Δ supports a single (optionally lagged) variable; got `$e`.")
    end
end

"""
Expand the difference operator `Δ`: `Δ(x)` becomes `x - x[-1]` and `Δ(x, n)`
becomes `x - x[-n]`, where `x` is a single (optionally lagged) variable. This is
pure syntactic sugar applied by [`@equations`](@ref).
"""
function expand_diff(x)
    x isa Expr || return x
    if x.head === :call && x.args[1] === :Δ
        if length(x.args) == 2          # Δ(x)
            arg = expand_diff(x.args[2])
            return Expr(:call, :-, arg, _lag(arg, 1))
        elseif length(x.args) == 3      # Δ(x, n)
            arg, n = expand_diff(x.args[2]), x.args[3]
            (n isa Integer && n > 0) || error("Δ(x, n): n must be a positive integer literal, got `$n`.")
            return Expr(:call, :-, arg, _lag(arg, n))
        else
            error("Δ takes one or two arguments, got $(length(x.args) - 1).")
        end
    end
    return Expr(x.head, map(expand_diff, x.args)...)
end

"""
Handle input variables in
- array form
- coma-seperated form
- whitespace seperated form
"""
function handle_input(input)
    if (length(input) == 1) && isa(input[1], Expr) && (input[1].head in (:vect, :tuple))
        input[1].args
    else
        input
    end
end