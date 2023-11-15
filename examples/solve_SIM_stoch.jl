using Consistent
using NLsolve
using Distributions
using Plots
using StatsPlots

# SIM_stoch
model = SIMStoch()
g_0 = 20.0
u_G = rand(Normal(0, 1), 1000 * 100)
u_T = rand(Normal(0, 0.25), 1000 * 100)
u_C = rand(Normal(0, 0.5), 1000 * 100)
exos = zeros(4, 1)
exos[1] = g_0
initial_guess = fill(1.0, length(model.endogenous_variables))
lags = fill(0.0, length(model.endogenous_variables))
lags = lags[:, :]
param_values = map(x -> params[x], model.parameters)
a_0 = solve(model, lags, exos, param_values)
simulation = zeros(101, 1000)
simulation[1, :] .= a_0[2]

for i in 1:1000
    a = a_0
    for j = 1:100
        exos[2] = u_G[j+(i-1)*100]
        exos[3] = u_T[j+(i-1)*100]
        exos[4] = u_C[j+(i-1)*100]
        a = solve(model, a[:, :], exos, param_values)
        simulation[j+1, i] = a[2]
    end
end

plot(simulation[:, 1])
violin(transpose(simulation[1:50, :]), linewidth = 0, legend = false)
# plot(simulation[1:30,1:1000], legend = false, seriestype = :scatter)

# DIS steady state
initial_guess = fill(1.0, length(sfc_model.endogenous_variables))
lags = fill(0.1, (length(sfc_model.endogenous_variables), 1)) # quite arbitrary
param_values = map(x -> get(values, x, nothing), sfc_model.parameters)
a = solve(initial_guess, lags, Matrix[], param_values)
for i in 1:1000
    a = solve(initial_guess, a[:,:], Matrix[], param_values)
end
a