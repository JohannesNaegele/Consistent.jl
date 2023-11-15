"""
Root-mean-square error of a time series.
"""
rmse(x, y) = sqrt(sum((x .- y).^2) / length(x))

"""
RMSE standardized by the mean of our target values.
"""
standardized_rmse(x, y) = rmse(x, y) / mean(y)

"""
Mean standardized RMSE for a vector of time series. Makes only sense for strictly positive variables.

Note: Without some kind of stationarity this estimation does not really make sense either,
but this is often a general problem of stock-flow consistent models.
"""
function msrmse(x, y)
    # loop over columns
    average = 0.0
    for i in axes(x, 2)
        average += standardized_rmse(x[:, i], y[:, i])
    end
    return average
end