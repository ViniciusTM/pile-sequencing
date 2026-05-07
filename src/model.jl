

function generate_piles_for_position(data::Data, position::Symbol)::Vector{Symbol}
    position_input_capacity = data.m_input_capacity[position]
    positions_min_size = data.m_position_min[position]
    
    # Para upper bound: assume que esta posição poderia receber todo o pool
    # de trens. Não cortar solução factível é mais importante que apertar o bound.
    train_arrival_left = sum(data.m_train)

    set_position_piles = [:P1]

    pile_mass = 0.0
    is_building = true
    for t in 1:data.n_periods
        if is_building
            road_input = min(position_input_capacity, data.m_local_arrival[t])
            
            train_input = min(position_input_capacity - road_input, train_arrival_left)
            train_arrival_left -= train_input
            
            total_input = road_input + train_input
            
            pile_mass += total_input
            if pile_mass >= positions_min_size
                pile_mass = positions_min_size # trunca no piso para gerar upper bound de pilhas
                is_building = false
            end
        else
            pile_mass -= data.m_line_demand[t]
            if pile_mass <= 0
                pile_mass = 0
                is_building = true
                name = Symbol("P$(length(set_position_piles)+1)")
                push!(set_position_piles, name)
            end
        end
    end
    
    return set_position_piles
end

function generate_piles(data::Data)::Dict{Symbol,Vector{Symbol}}
    set_position_piles = Dict{Symbol,Vector{Symbol}}()
    for position in data.s_positions
        position_piles = generate_piles_for_position(data, position)
        set_position_piles[position] = position_piles
    end
    return set_position_piles
end

function solve!(model::Model)
    optimize!(model)
    println("Status: ", termination_status(model))
    println("Contagem de resultados: ", result_count(model))
    println("FO: ", value(objective_function(model)))
end

function build_model(data::Data)::Model
    s_piles = generate_piles(data)

    model = Model(HiGHS.Optimizer)
    add_variables!(model, data, s_piles)
    add_pile_lifecycle_constraints!(model, data, s_piles)
    add_material_flow_constraints!(model, data, s_piles)
    add_objective!(model, data, s_piles)
    
    return model
end