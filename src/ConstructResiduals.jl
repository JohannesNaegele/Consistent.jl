function construct_residuals(name, function_body, args)
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
    println(f!)
    return f!
end