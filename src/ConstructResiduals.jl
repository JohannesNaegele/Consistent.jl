function construct_residuals_for_print(name, function_body)
    f! = quote
        function f!($(name[1]), $(name[2]), $(name[3]), $(name[4]), $(name[5]))
            nothing
        end
    end

    # construct function body
    for i in eachindex(function_body)
        function_body[i] = :($(name[1])[$i] = $(function_body[i]))
    end

    # add function body to function
    f!.args[2].args[end] = Expr(:block, function_body...)
    return f!
end

function construct_residuals(name, function_body)
    # write each residual expression into the output vector `diff` (= name[1])
    assignments = map(eachindex(function_body)) do i
        :($(name[1])[$i] = $(function_body[i]))
    end

    # bare anonymous function expression: (diff, endos, lags, exos, params) -> begin ... end
    # Returned as-is (no `quote`/`eval` wrapper) so it can be fed to
    # `@RuntimeGeneratedFunction` in `model`.
    return Expr(
        :function,
        Expr(:tuple, name[1], name[2], name[3], name[4], name[5]),
        Expr(:block, assignments...)
    )
end