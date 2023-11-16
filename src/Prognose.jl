function prognose!(results, horizon, model, exos, param_values; method=:broyden)
    for i in horizon
        sol = Consistent.solve_nonlinear(model, results[:, begin:i-1], exos, param_values, initial=results[:, i], method=method)
        if sol.retcode == ReturnCode.Failure
            return ReturnCode.Failure
        end
        results[:, i] = sol.u
    end
    return ReturnCode.Success
end