using Consistent
using NLsolve
using Distributions
using Plots
using StatsPlots

# SIM_stoch
scen = SIMStoch()           # a Scenario: model + calibration + data
sim = scen.model
g_0 = 20.0
u_G = rand(Normal(0, 1), 1000 * 100)
u_T = rand(Normal(0, 0.25), 1000 * 100)
u_C = rand(Normal(0, 0.5), 1000 * 100)
exos = zeros(4, 1)
exos[1] = g_0
initial_guess = fill(1.0, length(sim.endogenous_variables))
lags = fill(0.0, length(sim.endogenous_variables))
lags = lags[:, :]
param_values = Consistent.param_values(scen)
a_0 = solve(sim, lags, exos, param_values)
simulation = zeros(101, 1000)
simulation[1, :] .= a_0[2]

for i in 1:1000
    a = a_0
    for j = 1:100
        exos[2] = u_G[j+(i-1)*100]
        exos[3] = u_T[j+(i-1)*100]
        exos[4] = u_C[j+(i-1)*100]
        a = solve(sim, a[:, :], exos, param_values)
        simulation[j+1, i] = a[2]
    end
end

plot(simulation[:, 1])
violin(transpose(simulation[1:50, :]), linewidth = 0, legend = false)
# plot(simulation[1:30,1:1000], legend = false, seriestype = :scatter)

# TODO: turn this Monte-Carlo sketch into a proper probabilistic SIM example once
# the probabilistic-model machinery lands (see GitHub issue #40).