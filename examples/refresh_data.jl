# Refresh examples/data/worldbank_us.csv from the World Bank Indicators API.
#
# The API is keyless and returns JSON over plain REST, so this needs no credentials
# and no fragile data-wrapper dependency — just HTTP + JSON3. Run it occasionally to
# update the vendored snapshot; the examples read the committed CSV (not the API),
# so they stay reproducible and run offline / in CI.
#
#   julia --project=examples examples/refresh_data.jl

using HTTP, JSON3, DataFrames, CSV

const COUNTRY = "USA"
const YEARS   = "1995:2022"
# series mapped to SIM/PC-style variables (all current US$ levels)
const SERIES = (
    Y = "NY.GDP.MKTP.CD",   # GDP
    C = "NE.CON.PRVT.CD",   # household final consumption
    G = "NE.CON.GOVT.CD",   # government final consumption
)

"Fetch one World Bank indicator as a Dict{year => value}."
function fetch_series(code)
    url = "https://api.worldbank.org/v2/country/$COUNTRY/indicator/$code?format=json&per_page=20000&date=$YEARS"
    resp = HTTP.get(url)
    payload = JSON3.read(resp.body)
    observations = payload[2]  # [1] is metadata, [2] is the data array
    return Dict(parse(Int, String(o.date)) => Float64(o.value)
                for o in observations if o.value !== nothing)
end

cols  = Dict(name => fetch_series(code) for (name, code) in pairs(SERIES))
years = sort(collect(intersect((Set(keys(c)) for c in values(cols))...)))
df    = DataFrame(year = years)
for (name, c) in cols
    df[!, name] = [c[y] for y in years]
end

path = joinpath(@__DIR__, "data", "worldbank_us.csv")
mkpath(dirname(path))
CSV.write(path, df)
println("wrote ", nrow(df), " rows × ", ncol(df), " cols to ", path)
