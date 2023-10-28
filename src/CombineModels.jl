import Base: +

function +(model1::Model, model2::Model)
    undetermined = findall(in(model2.endogenous_variables), model1.endogenous_variables)
    @assert isempty(undetermined) "The endogenous variables $(model1[undetermined]) appear twice"
    exos1 = filter(x -> !(x in model2.endogenous_variables), model1.exogenous_variables)
    exos2 = filter(
        x -> !((x in model1.endogenous_variables) || (x in exos1)), model2.exogenous_variables
    )
    return model(
        endos=Variables(vcat(model1.endogenous_variables, model2.endogenous_variables)),
        exos=Variables(vcat(exos1, exos2)),
        params=Variables(vcat(model1.parameters, model2.parameters)),
        eqs=Equations(vcat(model1.equations, model2.equations))
    )
end