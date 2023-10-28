module Consistent

export @parameters, @equations, @variables
export model, solve

include("Helpers.jl")
include("ModelComponents.jl")
include("Model.jl")
include("Variables.jl")
include("ConstructResiduals.jl")
include("Macros.jl")
include("CombineModels.jl")
include("Solve.jl")

# include("models/SIM.jl")
# include("models/SIM_stoch.jl")
# include("models/LP.jl")
# include("models/DIS.jl")
# include("models/PC.jl")

end # module Consistent