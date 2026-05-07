function add_material_flow_constraints!(model::Model, data::Data, s_piles::Dict{Symbol,Vector{Symbol}})
    s_trains = 1:data.n_trains
    s_positions = data.s_positions
    s_periods = 1:data.n_periods

    B_TRAIN_TO_PILE = model[:B_TRAIN_TO_PILE]
    M_LOCAL_TO_PILE = model[:M_LOCAL_TO_PILE]
    N_TRAIN_TO_PILE = model[:N_TRAIN_TO_PILE]
    M_PILE_TO_LINE = model[:M_PILE_TO_LINE]
    M_PILE_INPUT = model[:M_PILE_INPUT]
    M_TO_LINE = model[:M_TO_LINE]
    B_PILE_BUILDING = model[:B_PILE_BUILDING]
    B_PILE_RECLAIMING = model[:B_PILE_RECLAIMING]
    B_PILE_USED = model[:B_PILE_USED]
    B_PILE_CONTINUE_RECLAIMING = model[:B_PILE_CONTINUE_RECLAIMING]
    B_PILE_END_RECLAIMING = model[:B_PILE_END_RECLAIMING]
    B_PILE_START_RECLAIMING = model[:B_PILE_START_RECLAIMING]
    M_PILE_OUTPUT = model[:M_PILE_OUTPUT]
    B_PILE_UNFINISHED = model[:B_PILE_UNFINISHED]

    # ------ Pile input flow

    @constraint(model, [i in s_trains],
        sum(B_TRAIN_TO_PILE[i,ps,p,t] for ps in s_positions for p in s_piles[ps] for t in s_periods) == 1
    )

    # Pile can receive mass only BUILDING
    for ps in s_positions, p in s_piles[ps], t in s_periods
        @constraint(model, M_LOCAL_TO_PILE[ps,p,t] <= B_PILE_BUILDING[ps,p,t] * data.m_input_capacity[ps])
        @constraint(model, N_TRAIN_TO_PILE[ps,p,t] <= B_PILE_BUILDING[ps,p,t] * data.n_trains_per_period_max[t])
    end

    # Pile can feed line only RECLAIMING
    @constraint(model, [ps in s_positions, p in s_piles[ps], t in s_periods], 
        M_PILE_TO_LINE[ps,p,t] <= (B_PILE_RECLAIMING[ps,p,t]) * data.m_line_demand[t]
    )

    # Min size for piles that start RECLAIMING
    @constraint(model, [ps in s_positions, p in s_piles[ps]], 
        M_PILE_INPUT[ps,p] >= data.m_position_min[ps] * B_PILE_USED[ps,p]
    )

    # Max size
    @constraint(model, [ps in s_positions, p in s_piles[ps]], 
        M_PILE_INPUT[ps,p] <= data.m_position_max[ps]
    )

    # ------ Pile output flow

    @variable(model, M_DEMAND_SLACK[t in s_periods] >= 0)
    @constraint(model, [t in s_periods],
        M_TO_LINE[t] == data.m_line_demand[t] - M_DEMAND_SLACK[t]
    )

    # Only one Pile can be on each of the RECLAIMING states
    @constraint(model, [t in s_periods], 
        sum(B_PILE_CONTINUE_RECLAIMING[ps,p,t] for ps in s_positions, p in s_piles[ps]) <= 1
    )
    @constraint(model, [t in s_periods], 
        sum(B_PILE_END_RECLAIMING[ps,p,t] for ps in s_positions, p in s_piles[ps]) <= 1
    )
    @constraint(model, [t in s_periods], 
        sum(B_PILE_START_RECLAIMING[ps,p,t] for ps in s_positions, p in s_piles[ps]) <= 1
    )

    # At most two piles can be on RECLAIMING states: one in START and other on END to guarantee demand is meet every day
    @constraint(model, [t in s_periods], 
        sum(B_PILE_RECLAIMING[ps,p,t] for ps in s_positions, p in s_piles[ps]) <= 2
    )

    # Mass INPUT in pile must be grater than mass OUTPUt
    @constraint(model, [ps in s_positions, p in s_piles[ps]],
        M_PILE_OUTPUT[ps,p] <=  M_PILE_INPUT[ps,p]
    )
    
    # INPUT mass can only exceed OUTPUT if the pile is UNFINISHED
    @constraint(model, c1[ps in s_positions, p in s_piles[ps]],
        M_PILE_OUTPUT[ps,p] - M_PILE_INPUT[ps,p] >= -data.m_position_max[ps] * (B_PILE_UNFINISHED[ps,p])
    )
end