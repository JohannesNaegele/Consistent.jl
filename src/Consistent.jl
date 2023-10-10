module Consistent

export @model, @endogenous, @exogenous, @parameters, @equations

include("Helpers.jl")
include("Model.jl")
include("Variables.jl")
include("Macros.jl")

end
