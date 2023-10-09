using Crayons

"""
Type for a stock-flow consistent model.
"""
mutable struct Model
    endogenous_variables::Vector{Symbol}
    exogenous_variables::Vector{Symbol}
    parameters::Vector{Symbol}
    math_operators::Set{Symbol}
    equations::Vector{Expr}
    f!::Function
end

Model() = Model(Symbol[], Symbol[], Symbol[], math_operators, Expr[], x -> nothing)

const math_operators = Set([:+, :-, :*, :/, :÷, :\, :^, :%])
const name = [:diff, :endos, :lags, :exos, :params]

function Base.show(io::IO, m::Model)
    descriptors = ["Endogenous Variables: ", "Exogenous Variables: ", "Parameters: ", "Equations: "]
    max_width = maximum(length.(descriptors))
    for i in eachindex(descriptors)
        descriptors[i] = descriptors[i] * ' '^(max_width - length(descriptors[i]))
    end
    print(io, Crayon(foreground = :green), descriptors[1]); println(io, Crayon(reset=true), m.endogenous_variables)
    print(io, Crayon(foreground = :yellow), descriptors[2]); println(io, Crayon(reset=true), m.exogenous_variables)
    print(io, Crayon(foreground = :blue), descriptors[3]); println(io, Crayon(reset=true), m.parameters)
    print(io, Crayon(foreground = :red), descriptors[4]); print(io, Crayon(reset=true))
    for i in 1:length(m.equations)
        print(io, "\n", ' '^max_width, "($i)  ", m.equations[i])
    end
end