function add_variables!(model::Model, data::Data, s_piles::Dict{Symbol,Vector{Symbol}})
    s_positions = data.s_positions
    s_periods = 1:data.n_periods
    s_trains = 1:data.n_trains
    s_train_window = Dict(i => data.t_train_window_start[i]:data.t_train_window_end[i] for i in s_trains)
   
    # --- Material flow to pile

    # Local
    @variable(model, M_LOCAL_TO_PILE[ps in s_positions, p in s_piles[ps], t in s_periods] >= 0)
    
    # Train
    @variable(model, B_TRAIN_TO_PILE[i in s_trains, ps in s_positions, p in s_piles[ps], t in s_train_window[i]], Bin)
    @expression(model, N_TRAIN_TO_PILE[ps in s_positions, p in s_piles[ps], t in s_periods], 
        sum(B_TRAIN_TO_PILE[i,ps,p,t] for i in s_trains if t in s_train_window[i])
    )
    @expression(model, M_TRAIN_TO_PILE[ps in s_positions, p in s_piles[ps], t in s_periods], 
        sum(B_TRAIN_TO_PILE[i,ps,p,t] * data.m_train[i] for i in s_trains if t in s_train_window[i])
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
    
    @expression(model, M_TO_LINE[t in s_periods],
        sum(M_PILE_TO_LINE[ps,p,t] for ps in s_positions, p in s_piles[ps])
    )
    
    @expression(model, M_PILE_OUTPUT[ps in s_positions, p in s_piles[ps]], 
        sum(M_PILE_TO_LINE[ps,p,t] for t in s_periods)
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