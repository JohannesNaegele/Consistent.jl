module Consistent

using RuntimeGeneratedFunctions
# Generate the model residual function `f!` without `eval`; this avoids world-age
# issues, keeps the module namespace clean, and makes model instantiation thread-safe.
RuntimeGeneratedFunctions.init(@__MODULE__)

# `solve` is a method of `CommonSolve.solve` (the same generic function used by
# NonlinearSolve), so `using Consistent, NonlinearSolve` does not clash on the name.
import CommonSolve
using CommonSolve: solve

# Plot recipes are defined with the lightweight RecipesBase, so Plots itself is
# not a dependency of the package.
using RecipesBase

export @parameters, @equations, @variables
export model, solve, operators!, add_params, add_exos, prognose!, onestep_prognose!
export Scenario, param_values, block_decomposition, reorder

include("Helpers.jl")
include("ModelComponents.jl")
include("Model.jl")
include("Variables.jl")
include("ConstructResiduals.jl")
include("Macros.jl")
include("Structure.jl")
include("CombineModels.jl")
include("Solve.jl")
include("Scenario.jl")
include("Plotting.jl")
include("Loss.jl")
include("Prognose.jl")

# Godley/Lavoie
include("models/SIM.jl")
include("models/SIM_stoch.jl")
include("models/LP.jl")
include("models/DIS.jl")
include("models/PC.jl")

include("models/BMW.jl")

end # module Consistent