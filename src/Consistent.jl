module Consistent

export @model, @endogenous, @exogenous, @parameters, @equations

include("HelperFunctions.jl")
include("Model.jl")
include("Variables.jl")
include("Macros.jl")

end
