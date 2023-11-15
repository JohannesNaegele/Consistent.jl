using NLsolve

function solve(model, lags, exos, params, initial=fill(1.0, length(model.endogenous_variables)))
    nlsolve(
        (x, y) -> model.f!(x, y, lags, exos, params),
        initial,
        autodiff = :forward,
    ).zero
end