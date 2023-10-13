using Consistent
using DataFrames
using ForwardDiff

function calibrate!(data, model, parameters=Dict())
    x -> model.f!(y, x, ...) + x
    function loss(data,)

    end
    ForwardDiff.derivative(() -> loss, input)
end

model = SIM()
df = DataFrame(reverse(lags[:, end-20:end-1], dims=2)', model.endogenous_variables)
df