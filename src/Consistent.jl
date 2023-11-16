module Consistent

export @parameters, @equations, @variables
export model, solve, operators!, add_params, add_exos, prognose!

include("Helpers.jl")
include("ModelComponents.jl")
include("Model.jl")
include("Variables.jl")
include("ConstructResiduals.jl")
include("Macros.jl")
include("CombineModels.jl")
include("Solve.jl")
include("Prognose.jl")

# Godley/Lavoie
include("models/SIM.jl")
include("models/SIM_stoch.jl")
include("models/LP.jl")
include("models/DIS.jl")
include("models/PC.jl")

include("models/BMW.jl")

end # module Consistent