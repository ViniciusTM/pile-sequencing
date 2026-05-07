
function add_objective!(model::Model, data::Data, s_piles::Dict{Symbol,Vector{Symbol}})
    s_periods = 1:data.n_periods
    M_DEMAND_SLACK = model[:M_DEMAND_SLACK]

    @objective(model, Min, sum(M_DEMAND_SLACK[t] for t in s_periods))
end