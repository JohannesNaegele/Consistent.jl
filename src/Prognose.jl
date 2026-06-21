# Dynamic forecasts: solve the model period by period, feeding solved values back
# in as lags. Return `true` on success, `false` if any period fails to converge.

function prognose!(results, horizon, model, exos, param_values; alg=NonlinearSolve.TrustRegion())
    for i in horizon
        sol = _solve_nonlinear(
            model, results[:, begin:i-1], exos, param_values; initial=results[:, i-1], alg=alg
        )
        sol.retcode == ReturnCode.Success || return false
        results[:, i] = sol.u
    end
    return true
end

function onestep_prognose!(results, reference_results, horizon, model, exos, param_values; alg=NonlinearSolve.TrustRegion())
    for i in horizon
        sol = _solve_nonlinear(
            model, reference_results[:, begin:i-1], exos, param_values; initial=reference_results[:, i-1], alg=alg
        )
        sol.retcode == ReturnCode.Success || return false
        results[:, i] = sol.u
    end
    return true
end
