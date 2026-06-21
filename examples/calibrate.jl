using Consistent
using DataFrames
using Plots
using Zygote
using Optimization
using OptimizationOptimJL
using SciMLSensitivity

# Given data for exogenous variables
df = DataFrame(:G => 20 .+ 10 * rand(60))

# Define model
scen = Consistent.SIM()
sim = scen.model
exos = permutedims(Matrix(df[!, sim.exogenous_variables]))
lags = scen.lags
params_dict = scen.params
param_values = map(x -> params_dict[x], sim.parameters)

# Solve model for 59 periods
for i in 1:59
    # assume we have some randomness in our parameters
    solution = Consistent.solve(sim, lags, exos[:, begin:i], param_values + 0.05 * rand(3))
    lags = hcat(lags, solution)
end

# Convert results to DataFrame
df = hcat(df, DataFrame(lags', sim.endogenous_variables))

function calibrate(data, model, opt_vars, opt_params, init_params)
    # Set up variables
    exos = permutedims(Matrix(data[!, model.exogenous_variables]))
    reference_results = permutedims(Matrix(data[!, model.endogenous_variables]))
    results = Matrix(data[!, model.endogenous_variables])' # lags in
    results[:, 1] = Vector(data[1, model.endogenous_variables])'
    param_values = map(x -> init_params[x], model.parameters)
    param_opt_inidices = Int[]
    for (i, p) in enumerate(model.parameters)
        if p in opt_params
            push!(param_opt_inidices, i)
        end
    end
    var_opt_indices = Int[]
    for (i, var) in enumerate(model.endogenous_variables)
        if var in opt_vars
            push!(var_opt_indices, i)
        end
    end
    initial = map(x -> init_params[x], opt_params)

    horizon = 2:(nrow(data))
    # println(horizon)

    # Define loss function
    function loss(p)
        pvalues = Zygote.Buffer(param_values)
        pvalues[1:length(param_values)] = param_values
        pvalues[param_opt_inidices] = p
        bresults = Zygote.Buffer(results)
        bresults[:] = results
        # converged = prognose!(bresults, horizon, model, exos, copy(pvalues))
        converged = onestep_prognose!(bresults, results, horizon, model, exos, copy(pvalues))
        # println(copy(bresults))
        # println(copy(pvalues))
        if !converged
            return Inf
        else
            # println(copy(bresults[:, 2:end]))
            return Consistent.msrmse(reference_results[:, 2:end], copy(bresults[:, 2:end]))
        end
    end

    # Numerical optimization
    adtype = Optimization.AutoZygote()
    optf = Optimization.OptimizationFunction((x, p) -> loss(x), adtype)
    optprob = Optimization.OptimizationProblem(optf, initial, lb = [0.0, 0.0], ub = [1.0, 1.0])
    res = Optimization.solve(optprob, SAMIN(), maxiters = 50000)
    return res
end

sol = calibrate(df, sim, [:Y, :C], [:α_1, :α_2], Dict(:α_1 => 0.5, :α_2 => 0.5, :θ => 0.2))

# Compare to fit
fitted = deepcopy(lags)
prognose!(fitted, 2:60, sim, exos, vcat(0.2, sol.u))
# prognose!(fitted, 2:60, sim, exos, vcat(0.2, [0.6, 0.4]))

# Compare data (solid) with the fitted trajectory (dashed) for selected variables
plt = plot(sim, lags; vars = [:Y, :C])
plot!(plt, sim, fitted; vars = [:Y, :C], linestyle = :dash)