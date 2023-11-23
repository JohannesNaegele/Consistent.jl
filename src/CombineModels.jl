import Base: +

function +(model1::Model, model2::Model)
    undetermined = findall(in(model2.endogenous_variables), model1.endogenous_variables)
    @assert isempty(undetermined) "The endogenous variables $(model1.endogenous_variables[undetermined]) appear twice"
    exos1 = filter(x -> !(x in model2.endogenous_variables), model1.exogenous_variables)
    exos2 = filter(
        x -> !((x in model1.endogenous_variables) || (x in exos1)), model2.exogenous_variables
    )
    return model(
        endos=Variables(vcat(model1.endogenous_variables, model2.endogenous_variables)),
        exos=Variables(vcat(exos1, exos2)),
        params=Variables(unique(vcat(model1.parameters, model2.parameters))),
        eqs=Equations(vcat(model1.equations, model2.equations))
    )
end

function add_params(model1::Model, params::Variables, verbose=false)
    return model(
        endos=model1.endogenous_variables,
        exos=model1.exogenous_variables,
        params=Variables(unique(vcat(model1.parameters, params))),
        eqs=model1.equations,
        verbose=verbose
    )
end

function add_exos(model1::Model, exos::Variables, verbose=false)
    return model(
        endos=model1.endogenous_variables,
        exos=Variables(unique(vcat(model1.exogenous_variables, exos))),
        params=model1.parameters,
        eqs=model1.equations,
        verbose=verbose
    )
end