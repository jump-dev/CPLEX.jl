function cpx_set_objective!(model::Model, cols::Vector{Int}, coefs::Vector{Float64})
    @assert length(cols) == length(coefs)
    @cpx_ccall_error(model.env, chgobj, Cint, (
        Ptr{Void},
        Ptr{Void},
        Cint,
        Ptr{Cint},
        Ptr{Cdouble}
        ),
        model.env.ptr, model.lp, Cint(length(cols)), Cint.(cols - 1), coefs)
end

function cpx_set_sense!(model::Model, sense::Symbol)
    if sense == :Min
        @cpx_ccall_error(model.env, chgobjsen, Void, (Ptr{Void}, Ptr{Void}, Cint), model.env.ptr, model.lp, 1)
    elseif sense == :Max
        @cpx_ccall_error(model.env, chgobjsen, Void, (Ptr{Void}, Ptr{Void}, Cint), model.env.ptr, model.lp, -1)
    else
        error("Unrecognized objective sense $sense")
    end
end

function cpx_get_sense(model::Model)
    sense_int = @cpx_ccall(getobjsen, Cint, (Ptr{Void}, Ptr{Void},), model.env.ptr, model.lp)
    if sense_int == 1
        return MOI.MinSense()
    elseif sense_int == -1
        return MOI.MaxSense()
    else
        error("CPLEX: problem object or environment does not exist")
    end
end
