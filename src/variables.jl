function add_variables!(model::Model, data::Data)

    @unpack s_piles, s_lines, s_line_positions, s_positions, s_periods, s_trains, s_train_window = data
    @unpack m_train = data

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
    @variable(model, B_PILE_START_RECLAIMING[ps in s_positions, p in s_piles[ps], t in s_periods], Bin)
    @variable(model, B_PILE_CONTINUE_RECLAIMING[ps in s_positions, p in s_piles[ps], t in s_periods], Bin)
    @variable(model, B_PILE_END_RECLAIMING[ps in s_positions, p in s_piles[ps], t in s_periods], Bin)    
    @variable(model, B_PILE_DONE[ps in s_positions, p in s_piles[ps], t in s_periods], Bin)
    
    # Reclaming states
    @expression(model, B_PILE_RECLAIMING[ps in s_positions, p in s_piles[ps], t in s_periods], 
        B_PILE_START_RECLAIMING[ps,p,t] + B_PILE_CONTINUE_RECLAIMING[ps,p,t] + B_PILE_END_RECLAIMING[ps,p,t]
    )

    # Final states
    @expression(model, B_PILE_USED[ps in s_positions, p in s_piles[ps]], 
        B_PILE_DONE[ps,p,s_periods[end]] + B_PILE_RECLAIMING[ps,p,s_periods[end]]
    )
    @expression(model, B_PILE_UNFINISHED[ps in s_positions, p in s_piles[ps]], 
        B_PILE_BUILDING[ps,p,s_periods[end]] + B_PILE_START_RECLAIMING[ps,p,s_periods[end]] + B_PILE_CONTINUE_RECLAIMING[ps,p,s_periods[end]]
    )

end