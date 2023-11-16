using Consistent
using DataFrames
using Zygote
using Optimization
using OptimizationOptimJL
using SciMLSensitivity

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

    # println(exos)
    # println(param_values)
    # println(param_opt_inidices)
    # println(var_opt_indices)
    # println(initial)
    horizon = 2:(ncol(data))

    # Define loss function
    function loss(p)
        pvalues = Zygote.Buffer(param_values)
        pvalues[param_opt_inidices] = p
        bresults = Zygote.Buffer(results)
        sol = prognose!(bresults, horizon, model, exos, copy(pvalues); method=:broyden)
        if sol == ReturnCode.Failure
            return Inf
        else
            return Consistent.msrmse(reference_results, copy(bresults))
        end
    end

    # Numerical optimization
    adtype = Optimization.AutoZygote()
    optf = Optimization.OptimizationFunction((x, p) -> loss(x), adtype)
    optprob = Optimization.OptimizationProblem(optf, initial)
    res = Optimization.solve(optprob, BFGS(), maxiters = 1000)
    return res
end

# Given data for exogenous variables
df = DataFrame(:G => 20 .+ 10 * rand(60))

# Define model
sim = Consistent.SIM()[:model]
exos = permutedims(Matrix(df[!, sim.exogenous_variables]))
lags = Consistent.SIM()[:lags]
params_dict = Consistent.SIM()[:params]
param_values = map(x -> params_dict[x], sim.parameters)

# Solve model for 59 periods
for i in 1:59
    # assume we have some randomness in our parameters
    solution = Consistent.solve(sim, lags, exos[:, begin:i], param_values + 0.1 * rand(3))
    lags = hcat(lags, solution)
end

# Convert results to DataFrame
df = hcat(df, DataFrame(lags', sim.endogenous_variables))
sol = calibrate(df, sim, [:Y, :T, :YD, :C], [:α_1, :α_2], Dict(:α_1 => 0.5, :α_2 => 0.5, :θ => 0.2))

# Consistent.solve_nonlinear(sim, lags, exos[:, 1], param_values + 0.1 * rand(3))