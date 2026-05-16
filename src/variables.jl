function add_variables!(model::Model, data::Data)

    @unpack s_compounds, s_piles, s_lines, s_line_positions, s_positions, s_periods, s_trains, s_train_window = data
    @unpack m_train, p_local_quality, p_train_quality, m_line_demand, k_position_line, d_setup_to_recaiming = data

    # --- Material flow to pile

    # Local
    @variable(model, M_LOCAL_TO_PILE[ps in s_positions, p in s_piles[ps], t in s_periods] >= 0)
    
    # Train
    @variable(model, B_TRAIN_TO_PILE[i in s_trains, ps in s_positions, p in s_piles[ps], t in s_train_window[i]], Bin)
    @expression(model, N_TRAIN_TO_PILE[ps in s_positions, p in s_piles[ps], t in s_periods], 
        sum(B_TRAIN_TO_PILE[i,ps,p,t] for i in s_trains if t in s_train_window[i])
    )
    @expression(model, M_TRAIN_TO_PILE[ps in s_positions, p in s_piles[ps], t in s_periods], 
        sum(B_TRAIN_TO_PILE[i,ps,p,t] * m_train[i] for i in s_trains if t in s_train_window[i])
    )

    # Total
    @expression(model, M_TO_PILE[ps in s_positions, p in s_piles[ps], t in s_periods], 
        M_LOCAL_TO_PILE[ps,p,t] + M_TRAIN_TO_PILE[ps,p,t]
    )
    @expression(model, M_PILE_INPUT[ps in s_positions, p in s_piles[ps]], 
        sum(M_TO_PILE[ps,p,t] for t in s_periods)
    )
    
    # --- Material flow to line

    @variable(model, M_PILE_TO_LINE[ps in s_positions, p in s_piles[ps], t in s_periods] >= 0)
    
    @expression(model, M_TO_LINE[d in s_lines, t in s_periods],
        sum(M_PILE_TO_LINE[ps,p,t] for ps in s_line_positions[d], p in s_piles[ps])
    )
    
    @expression(model, M_PILE_OUTPUT[ps in s_positions, p in s_piles[ps]], 
        sum(M_PILE_TO_LINE[ps,p,t] for t in s_periods)
    )

    # --- Mass balance in pile

    @expression(model, M_IN_PILE[ps in s_positions, p in s_piles[ps], t in s_periods],
        sum(M_TO_PILE[ps,p,t2] for t2 in s_periods[1:t]) - sum(M_PILE_TO_LINE[ps,p,t2] for t2 in s_periods[1:t])
    )

    # --- Pile state

    # Base states
    @variable(model, B_PILE_EMPTY[ps in s_positions, p in s_piles[ps], t in s_periods], Bin)
    @variable(model, B_PILE_BUILDING[ps in s_positions, p in s_piles[ps], t in s_periods], Bin)
    @variable(model, B_PILE_END_BUILDING[ps in s_positions, p in s_piles[ps], t in s_periods], Bin)
    @variable(model, B_PILE_RECLAIMING[ps in s_positions, p in s_piles[ps], t in s_periods], Bin)
    @variable(model, B_PILE_END_RECLAIMING[ps in s_positions, p in s_piles[ps], t in s_periods], Bin)    
    @variable(model, B_PILE_DONE[ps in s_positions, p in s_piles[ps], t in s_periods], Bin)
    
    # Reclaming states
    @expression(model, B_PILE_ALL_RECLAIMING[ps in s_positions, p in s_piles[ps], t in s_periods], 
        B_PILE_RECLAIMING[ps,p,t] + B_PILE_END_RECLAIMING[ps,p,t]
    )

    # Building states
    @expression(model, B_PILE_ALL_BUILDING[ps in s_positions, p in s_piles[ps], t in s_periods], 
        B_PILE_BUILDING[ps,p,t] + B_PILE_END_BUILDING[ps,p,t]
    )

    # Final states
    @expression(model, B_PILE_USED[ps in s_positions, p in s_piles[ps]], 
        B_PILE_DONE[ps,p,s_periods[end]] + B_PILE_ALL_RECLAIMING[ps,p,s_periods[end]]
    )
    @expression(model, B_PILE_UNFINISHED[ps in s_positions, p in s_piles[ps]], 
        B_PILE_BUILDING[ps,p,s_periods[end]] + B_PILE_RECLAIMING[ps,p,s_periods[end]]
    )

    # --- Pile quality

    @expression(model, M_COMP_TO_PILE[ps in s_positions, p in s_piles[ps], q in s_compounds, t in s_periods],
        (M_LOCAL_TO_PILE[ps,p,t] * p_local_quality[q,t]/100) 
        + sum(B_TRAIN_TO_PILE[i,ps,p,t] * m_train[i] * p_train_quality[i,q]/100 for i in s_trains if t in s_train_window[i])
    )

    @expression(model, M_COMP_PILE[ps in s_positions, p in s_piles[ps], q in s_compounds],
        sum(M_COMP_TO_PILE[ps,p,q,t] for t in s_periods)
    )

    # --- Positions aggregation

    # Since only one pile can be BUILDING in a position and period, ∑ in piles only removes de indexation
    @expression(model, M_LOCAL_TO_POSITION[ps in s_positions,t in s_periods], 
        sum(M_LOCAL_TO_PILE[ps,p,t] for p in s_piles[ps])
    )
    @expression(model, M_TO_POSITION[ps in s_positions,t in s_periods],
        sum(M_TO_PILE[ps,p,t] for p in s_piles[ps])
    )
    @expression(model, B_POSITION_END_BUILDING[ps in s_positions, t in s_periods],
        sum(B_PILE_END_BUILDING[ps,p,t] for p in s_piles[ps])
    )

    # Since only one pile can be CONSUMING in a position and period, ∑ in piles only removes de indexation
    @expression(model, M_POSITION_TO_LINE[ps in s_positions,t in s_periods],
        sum(M_PILE_TO_LINE[ps,p,t] for p in s_piles[ps])
    )

    # --- Durations

    # Time (hours) spend in the building state
    @variable(model, D_BUILDING[ps in s_positions, t in s_periods] >= 0)

    # Time spend in a day reclaming the pile
    @expression(model, D_RECLAIMING[ps in s_positions,t in s_periods],
       (m_line_demand[k_position_line[ps],t] > 0) ? (M_POSITION_TO_LINE[ps,t] / m_line_demand[k_position_line[ps],t]) * 24 : 0
    )

    # Time spend afeter building in quality assertions
    @variable(model, D_QUALITY_ASSERTION[ps in s_positions,t in s_periods] >= 0)

end