function add_material_flow_constraints!(model::Model, data::Data)
    
    @unpack s_piles, s_lines, s_line_positions, s_trains, s_positions, s_periods = data
    @unpack k_position_line, m_input_capacity, n_trains_per_period_max, m_line_demand, m_position_min, m_position_max, m_local_arrival = data

    B_TRAIN_TO_PILE = model[:B_TRAIN_TO_PILE]
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
    M_TO_PILE = model[:M_TO_PILE]
    M_LOCAL_TO_PILE = model[:M_LOCAL_TO_PILE]


    # ------ Local arrival

    # All local arrival must be directed to a pile
    @constraint(model, [t in s_periods],
        sum(M_LOCAL_TO_PILE[ps,p,t] for ps in s_positions, p in s_piles[ps]) == m_local_arrival[t]
    )

    # ------ Trains arrival

    # Each train can arrive only once
    @constraint(model, [i in s_trains],
        sum(B_TRAIN_TO_PILE[i,ps,p,t] for ps in s_positions for p in s_piles[ps] for t in s_periods) == 1
    )

    # Maximum number trains arriving in one day
    @constraint(model, [t in s_periods],
        sum(N_TRAIN_TO_PILE[ps,p,t] for ps in s_positions for p in s_piles[ps]) <= n_trains_per_period_max[t]
    )

    # ------ Pile input flow

    # Pile can receive mass only BUILDING
    @constraint(model, [ps in s_positions, p in s_piles[ps], t in s_periods],
        M_TO_PILE[ps,p,t] <= m_input_capacity[ps] * B_PILE_BUILDING[ps,p,t]
    )


    # Pile can feed line only RECLAIMING
    @constraint(model, [ps in s_positions, p in s_piles[ps], t in s_periods], 
        M_PILE_TO_LINE[ps,p,t] <= (B_PILE_RECLAIMING[ps,p,t]) * m_line_demand[k_position_line[ps],t]
    )

    # Min size for piles that start RECLAIMING
    @constraint(model, [ps in s_positions, p in s_piles[ps]], 
        M_PILE_INPUT[ps,p] >= m_position_min[ps] * B_PILE_USED[ps,p]
    )

    # Max size
    @constraint(model, [ps in s_positions, p in s_piles[ps]], 
        M_PILE_INPUT[ps,p] <= m_position_max[ps]
    )

    # ------ Pile output flow

    @variable(model, M_DEMAND_SLACK[d in s_lines, t in s_periods] >= 0)
    @constraint(model, [d in s_lines, t in s_periods],
        M_TO_LINE[d,t] == m_line_demand[d,t] - M_DEMAND_SLACK[d,t]
    )
    @expression(model, TOTAL_DEMAND_SLACK, 
        sum(M_DEMAND_SLACK[d,t] for d in s_lines, t in s_periods)
    )

    # For each line, only one of its Piles can be on each of the RECLAIMING states
    @constraint(model, [d in s_lines, t in s_periods], 
        sum(B_PILE_CONTINUE_RECLAIMING[ps,p,t] for ps in s_line_positions[d], p in s_piles[ps]) <= 1
    )
    @constraint(model, [d in s_lines, t in s_periods], 
        sum(B_PILE_END_RECLAIMING[ps,p,t] for ps in s_line_positions[d], p in s_piles[ps]) <= 1
    )
    @constraint(model, [d in s_lines, t in s_periods], 
        sum(B_PILE_START_RECLAIMING[ps,p,t] for ps in s_line_positions[d], p in s_piles[ps]) <= 1
    )

    # For each line, we cannot have CONTINUE and (START | END) piles but we can have a START and END piles
    @constraint(model, [d in s_lines, t in s_periods], 
        sum(B_PILE_CONTINUE_RECLAIMING[ps,p,t] + B_PILE_START_RECLAIMING[ps,p,t] for ps in s_line_positions[d], p in s_piles[ps]) <= 1
    )
    @constraint(model, [d in s_lines, t in s_periods], 
        sum(B_PILE_CONTINUE_RECLAIMING[ps,p,t] + B_PILE_END_RECLAIMING[ps,p,t] for ps in s_line_positions[d], p in s_piles[ps]) <= 1
    )

    # Mass INPUT in pile must be grater than mass OUTPUt
    @constraint(model, [ps in s_positions, p in s_piles[ps]],
        M_PILE_OUTPUT[ps,p] <=  M_PILE_INPUT[ps,p]
    )
    
    # INPUT mass can only exceed OUTPUT if the pile is UNFINISHED
    @constraint(model, c1[ps in s_positions, p in s_piles[ps]],
        M_PILE_OUTPUT[ps,p] - M_PILE_INPUT[ps,p] >= -m_position_max[ps] * (B_PILE_UNFINISHED[ps,p])
    )
end