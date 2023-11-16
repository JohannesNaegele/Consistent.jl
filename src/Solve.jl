using NLsolve
using LinearAlgebra
import Optimization
import Optim
using NonlinearSolve
using SimpleNonlinearSolve

function solve(model, lags, exos, params; initial=fill(1.0, length(model.endogenous_variables)), method=:newton)
    nlsolve(
        (F, x) -> model.f!(F, x, lags, exos, params),
        initial,
        autodiff = :forward,
        method = method,
        # iterations = 500,
        ftol = 1e-40,
        xtol = 1e-40
    ).zero
end

function solve_nonlinear(model, lags, exos, params; initial=fill(1.0, length(model.endogenous_variables)), method=:newton)
    prob = NonlinearSolve.NonlinearProblem(
        (F, x, p) -> model.f!(F, x, lags, exos, params),
        initial,#
        abstol = 1e-40, reltol = 1e-40
    )
    sol = NonlinearSolve.solve(prob, NonlinearSolve.TrustRegion())
    return sol
end

# function solve_optim(model, lags, exos, params; initial=fill(1.0, length(model.endogenous_variables)), method=:newton)
#     f = (x, y) -> model.f!(x, y, lags, exos, params)
#     prob = Optimization.OptimizationProblem(
#         x -> max(norm(f(x, y)) + abs(f(x, y)[1] - f(x, y)[1])),
#         initial,
#         Optimization.AutoForwardDiff()
#     )
#     sol = Optimization.solve(prob, Optim.BFGS())
# end