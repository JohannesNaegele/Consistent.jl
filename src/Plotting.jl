using RecipesBase

"""
Plot recipe for solved trajectories.

    plot(model, results)

draws each endogenous variable over time, where `results` has one row per
endogenous variable (in the order of `model.endogenous_variables`) and one column
per period. Restrict the plotted variables with the `vars` keyword:

    plot(model, results; vars = [:Y, :C])

Defining the recipe with `RecipesBase` keeps Plots out of the package's
dependencies — the plot is only realised once the user loads Plots.jl.
"""
@recipe function f(model::Model, results::AbstractMatrix)
    endos = model.endogenous_variables
    vars = get(plotattributes, :vars, collect(endos))
    xguide --> "period"
    yguide --> "value"
    for v in vars
        i = findfirst(==(v), endos)
        i === nothing && error("`$v` is not an endogenous variable of the model.")
        @series begin
            label --> string(v)
            results[i, :]
        end
    end
end
