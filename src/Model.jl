using Crayons

"""
Type for a stock-flow consistent model.

The most important part is the automatically generated function `f!` which has the following form:
    model.f!(residuals, endos, lags, exos, params)
Intuitively, we evaluate our function `f(endos, ...)`` (which should equal zero) into residuals.
"""
struct Model
    endogenous_variables::Variables
    exogenous_variables::Variables
    parameters::Variables
    equations::Equations
    f!
end

const math_operators = Set([:+, :-, :*, :/, :÷, :\, :^, :%])
const name = [:diff, :endos, :lags, :exos, :params]

function Base.show(io::IO, m::Model)
    descriptors = ["Endogenous Variables: ", "Exogenous Variables: ", "Parameters: ", "Equations: "]
    max_width = maximum(length.(descriptors))
    for i in eachindex(descriptors)
        descriptors[i] = descriptors[i] * ' '^(max_width - length(descriptors[i]))
    end
    println("Stock-flow consistent model")
    print(io, Crayon(foreground = :green), descriptors[1]); println(io, Crayon(reset=true), m.endogenous_variables)
    print(io, Crayon(foreground = :yellow), descriptors[2]); println(io, Crayon(reset=true), m.exogenous_variables)
    print(io, Crayon(foreground = :blue), descriptors[3]); println(io, Crayon(reset=true), m.parameters)
    print(io, Crayon(foreground = :red), descriptors[4]); print(io, Crayon(reset=true))
    for i in eachindex(m.equations)
        print(io, "\n", ' '^max_width, "($i)  ", m.equations[i])
    end
end