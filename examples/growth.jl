using Consistent
using Plots

include("GROWTH_eqs.jl")

const T = 350
lags = map(x -> initial_dict[x] isa Number ? Float64(initial_dict[x]) : 0.0, growth.endogenous_variables)[:, :]
exos_const = map(x -> Float64(initial_dict[x]), growth.exogenous_variables)
exos = hcat(exos_const, exos_const)
param_values = map(x -> Float64(params_dict[x]), growth.parameters)

# Solve model for T periods
function progn(model, lags, exos, param_values; method=:trust_region)
    results = zeros(length(model.endogenous_variables), T)
    results[:, 1] = lags
    for i in 1:(T-1)
        solution = solve(model, results[:, i], exos, param_values; initial=results[:, i], method=method)
        results[:, i+1] = solution
    end
    return results
end

@time results = progn(growth, lags, exos, param_values)
# compare:
# @time results = progn(growth, lags, exos, param_values; method=:broyden)

# Plot bank bonds supplied/demanded as a share of capital K
row(v) = results[findfirst(==(v), growth.endogenous_variables), :]
K = row(:K)
plot(1:T, row(:Bbs) ./ K; label = "Bbs/K", xlabel = "period")
plot!(1:T, row(:Bbd) ./ K; label = "Bbd/K")

# @report_opt Consistent.f!(a, lags, lags, exos, param_values)
# growth.equations[findfirst(==(:G), growth.endogenous_variables)]