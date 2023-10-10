"""
Macro to specify the endogenous variables.

# Example:
    @endogenous Y C
"""
macro endogenous(input...)
    Consistent.sfc_model.endogenous_variables = remove_expr([input...])
end

"""
Macro to specify the exogenous variables.

# Example:
    @exogenous G X
"""
macro exogenous(input...)
    Consistent.sfc_model.exogenous_variables = remove_expr([input...])
end

"""
Macro to specify the parameters.

# Example:
    @parameters α θ
"""
macro parameters(input...)
    Consistent.sfc_model.parameters = remove_expr([input...])
end

"""
Macro to specify the model equations. Use `begin ... end`.

# Example:
    @equations begin
        Y = G + C
    end
"""
macro equations(input...) # FIXME: refactor
    ex = remove_blocks(MacroTools.striplines(input...))
    Consistent.sfc_model.equations = deepcopy(ex.args)
    function_body = deepcopy(ex.args)

    # we need block input (begin ... end)
    if (ex.head == :block)
        for i in eachindex(function_body)
            # check if we really have a proper equation
            if (function_body[i].head == :(=))
                function_body[i] =
                    :($(function_body[i].args[1]) - $(function_body[i].args[2]))
            else
                error("Only equalities are supported.")
            end
        end
    else
        error("Block input expected")
    end

    # construct arrays for different types of variables
    found = vars(function_body) # all found variables
    endos = Consistent.sfc_model.endogenous_variables # endogenous variables
    exos = Consistent.sfc_model.exogenous_variables # exogenous variables
    params = Consistent.sfc_model.parameters # parameters
    variables = union(Set(endos), Set(exos), Set(params)) # all variables

    # check for unused variables from specification
    if issubset(variables, found)
        function_body = replace_vars(function_body, endos, exos, params, name[2:5])
    else
        error("$(setdiff(variables, found)) unused!")
    end

    # construct function for residuals of model variables
    return MacroTools.striplines(:(Consistent.sfc_model.f! = $(construct_residuals(name, function_body, ex))))
end

"""
Macro to build a stock-flow consistent model.

# Example:
```julia-repl
julia> @model begin
    @endogenous Y T YD C H_s H_h H
    @exogenous G
    @parameters θ α_1 α_2
    @equations begin
        Y = C + G
        T = θ * Y
        YD = Y - T
        C = α_1 * YD + α_2 * H[-1]
        H_s + H_s[-1] = G - T
        H_h + H_h[-1] = YD - C
        H = H_s + H_s[-1] + H[-1]
    end
end
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
macro model(input...)
    global Consistent.sfc_model = Model()
    eval(input...)
    return deepcopy(Consistent.sfc_model)
end