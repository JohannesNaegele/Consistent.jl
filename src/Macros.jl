function build_f!(endos, exos, params, args)
    endos = endos.variables
    exos = exos.variables
    params = params.variables

    function_body = deepcopy(args)
    for i in eachindex(function_body)
        # check if we really have a proper equation
        if (function_body[i].head == :(=))
            function_body[i] =
                :($(function_body[i].args[1]) - $(function_body[i].args[2]))
        else
            error("Only equalities are supported.")
        end
    end

    # construct arrays for different types of variables
    found = vars(function_body) # all found variables
    variables = union(Set(endos), Set(exos), Set(params)) # all variables

    # check for unused variables from specification
    if issubset(variables, found)
        function_body = replace_vars(function_body, endos, exos, params, name[2:5])
    else
        error("$(setdiff(variables, found)) unused!\n\nUsed: $found")
    end

    # construct function for residuals of model variables
    return MacroTools.striplines(:(Consistent.f! = $(construct_residuals(name, function_body, args))))
end

"""
Macro to build a stock-flow consistent model.

# Example:
```julia-repl
julia> model(
    endos = @variables(Y, T, YD, C, H_s, H_h, H),
    exos = @variables(G),
    params = @variables(θ, α_1, α_2),
    eqs = @equations begin
        Y = C + G
        T = θ * Y
        YD = Y - T
        C = α_1 * YD + α_2 * H[-1]
        H_s + H_s[-1] = G - T
        H_h + H_h[-1] = YD - C
        H = H_s + H_s[-1] + H[-1]
    end
)
Stock-flow consistent model
Endogenous Variables: [:Y, :T, :YD, :C, :H_s, :H_h, :H]
Exogenous Variables:  [:G]
Parameters:           [:θ, :α_1, :α_2]
Equations:            
                      (1)  Y = C + G
                      (2)  T = θ * Y
                      (3)  YD = Y - T
                      (4)  C = α_1 * YD + α_2 * H[-1]
                      (5)  H_s + H_s[-1] = G - T
                      (6)  H_h + H_h[-1] = YD - C
                      (7)  H = H_s + H_s[-1] + H[-1]
```
"""
function model(;
    endos=nothing::Union{Variables, Nothing},
    exos=Variables(),
    params=Variables()::Union{Variables, OrderedDict},
    eqs,
    verbose=false
)
    if params isa OrderedDict # FIXME: use promotion
        parameters = Variables(params)
    else # FIXME
        parameters = params
    end

    if isnothing(endos)
        endos = Variables(left_symbol.(eqs.exprs))
    end

    if verbose
        println(build_f!(endos, exos, parameters, eqs.exprs))
    end

    eval(build_f!(endos, exos, parameters, eqs.exprs))
    return Model(
        endos,
        exos,
        parameters,
        eqs,
        deepcopy(Consistent.f!)
    )
end

operators!(x) = union!(math_operators, x)