function prognose!(results, horizon, model, exos, param_values; method=:broyden)
    for i in horizon
        sol = Consistent.solve_nonlinear(model, results[:, begin:i-1], exos, param_values, initial=results[:, i-1], method=method)
        if sol.retcode == ReturnCode.Failure
            return ReturnCode.Failure
        end
        results[:, i] = sol.u
    end
    return ReturnCode.Success
end

function onestep_prognose!(results, reference_results, horizon, model, exos, param_values; method=:broyden)
    for i in horizon
        sol = Consistent.solve_nonlinear(model, reference_results[:, begin:i-1], exos, param_values, initial=reference_results[:, i-1], method=method)
        if sol.retcode == ReturnCode.Failure
            return ReturnCode.Failure
        end
        results[:, i] = sol.u
    end
    return ReturnCode.Success
end