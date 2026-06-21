using NLsolve
using LinearAlgebra
using NonlinearSolve

# Map a method symbol to a NonlinearSolve algorithm.
function _nonlinear_alg(method::Symbol)
    method === :trust_region && return NonlinearSolve.TrustRegion()
    method === :broyden      && return NonlinearSolve.Broyden()
    method === :newton_raphson && return NonlinearSolve.NewtonRaphson()
    error("Unknown method `:$method`. Use :newton, :trust_region, :broyden, or :newton_raphson.")
end

"""
    solve(model, lags, exos, params; initial, method) -> Vector

Solve `model` for a single period and return the vector of endogenous variable
values, ordered as in `model.endogenous_variables`.

`method` selects the algorithm:
- `:newton` (default) — NLsolve's Newton method;
- `:trust_region`, `:broyden`, `:newton_raphson` — the corresponding NonlinearSolve algorithms.

This is a method of `CommonSolve.solve`, so it shares the `solve` name with
NonlinearSolve/DifferentialEquations without clashing.
"""
function CommonSolve.solve(
    model::Model, lags, exos, params;
    initial=fill(1.0, length(model.endogenous_variables)),
    method::Symbol=:newton
)
    if method === :newton
        return nlsolve(
            (F, x) -> model.f!(F, x, lags, exos, params),
            initial,
            autodiff=:forward,
            ftol=1e-40,
            xtol=1e-40
        ).zero
    else
        return _solve_nonlinear(
            model, lags, exos, params; initial=initial, alg=_nonlinear_alg(method)
        ).u
    end
end

# Internal: returns the raw NonlinearSolve solution (with `.u` and `.retcode`).
# Used by the forecasting routines, which need convergence information.
function _solve_nonlinear(
    model::Model, lags, exos, params;
    initial=fill(1.0, length(model.endogenous_variables)),
    alg=NonlinearSolve.TrustRegion()
)
    prob = NonlinearProblem(
        (F, x, p) -> model.f!(F, x, lags, exos, p),
        initial,
        params,
        abstol=1e-40,
        reltol=1e-40
    )
    return NonlinearSolve.solve(prob, alg)
end
