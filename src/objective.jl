
function add_objective!(model::Model)

    @objective(model, Min, model[:TOTAL_DEMAND_SLACK])
    
end