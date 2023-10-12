function +(model1::Model, model2::Model)
    undetermined = findall(in(model2.endogenous_variables), model1.endogenous_variables)
    @assert isempty(undetermined) "The endogenous variables $(model1[undetermined]) appear twice"
    exos1 = filter(x -> !(x in model2.endogenous_variables), model1.exogenous_variables)
    exos2 = filter(
        x -> !((x in model1.endogenous_variables) || (x in exos1)), model2.exogenous_variables
    )
    equations = vcat(model1.equations, model2.equations)
    global Consistent.sfc_model = Model()
    sfc_model.endogenous_variables = vcat(model1.endogenous_variables, model2.endogenous_variables)
    sfc_model.exogenous_variables = vcat(exos1, exos2)
    sfc_model.parameters = vcat(model1.parameters, model2.parameters)
    println(typeof(sfc_model.math_operators))
    println(typeof(model1.math_operators))
    sfc_model.math_operators = model1.math_operators # FIXME: does this make sense?
    sfc_model.equations = equations
    eval(build_f!(equations))
    deepcopy(sfc_model)
end