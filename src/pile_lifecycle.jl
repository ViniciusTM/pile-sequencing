function add_pile_lifecycle_constraints!(model::Model, data::Data)
    
    @unpack s_piles, s_positions, s_periods = data

    B_PILE_EMPTY = model[:B_PILE_EMPTY]
    B_PILE_BUILDING = model[:B_PILE_BUILDING]
    B_PILE_END_BUILDING = model[:B_PILE_END_BUILDING]
    B_PILE_RECLAIMING = model[:B_PILE_RECLAIMING]
    B_PILE_END_RECLAIMING = model[:B_PILE_END_RECLAIMING]
    B_PILE_DONE = model[:B_PILE_DONE]

    # With exeption of END_BUILDING, a pile can only be in one state at a time
    @constraint(model, [ps in s_positions, p in s_piles[ps], t in s_periods], 
        + B_PILE_EMPTY[ps,p,t] 
        + B_PILE_BUILDING[ps,p,t]
        + B_PILE_RECLAIMING[ps,p,t] 
        + B_PILE_END_RECLAIMING[ps,p,t]
        + B_PILE_DONE[ps,p,t] == 1
    )
    @constraint(model, [ps in s_positions, p in s_piles[ps], t in s_periods], 
        B_PILE_BUILDING[ps,p,t] + B_PILE_END_BUILDING[ps,p,t] <= 1
    )


    # Initial state can only be EMPTY || BUILDING
    @constraint(model, [ps in s_positions, p in s_piles[ps]], 
        B_PILE_EMPTY[ps,p,1] + B_PILE_BUILDING[ps,p,1] == 1
    )
    @constraint(model, [ps in s_positions, p in s_piles[ps]], 
        B_PILE_END_BUILDING[ps,p,1] == 0
    )

    # Piles can stay EMPTY, but cannot become EMPTY
    @constraint(model, [ps in s_positions, p in s_piles[ps], t in s_periods[2:end]],
        B_PILE_EMPTY[ps,p,t] <= B_PILE_EMPTY[ps,p,t-1]
    )

    # Piles can stay BUILDING, or become BUILDING from EMPTY
    @constraint(model, [ps in s_positions, p in s_piles[ps], t in s_periods[2:end]],
        B_PILE_BUILDING[ps,p,t] <= B_PILE_BUILDING[ps,p,t-1] + B_PILE_EMPTY[ps,p,t-1]
    )
    
    # Pile cannot stay BUILDING_END, but can become BUILDING_END from BUILDING
    @constraint(model, [ps in s_positions, p in s_piles[ps], t in s_periods[2:end]],
        B_PILE_END_BUILDING[ps,p,t] <= B_PILE_BUILDING[ps,p,t-1]
    )

    # Piles stay RECLAIMING, or become RECLAIMING after or while on END_BUILDING
    @constraint(model, [ps in s_positions, p in s_piles[ps], t in s_periods[2:end]],
        B_PILE_RECLAIMING[ps,p,t] <= B_PILE_RECLAIMING[ps,p,t-1] + B_PILE_END_BUILDING[ps,p,t-1] + B_PILE_END_BUILDING[ps,p,t]
    )

    # Piles cannot stay END_RECLAIMING, but can become END_RECLAIMING from RECLAIMING
    @constraint(model, [ps in s_positions, p in s_piles[ps], t in s_periods[2:end]],
        B_PILE_END_RECLAIMING[ps,p,t] <= B_PILE_RECLAIMING[ps,p,t-1] + B_PILE_END_BUILDING[ps,p,t-1]
    )

    # Piles can stay DONE, or become DONE from END_RECLAIMING
    @constraint(model, [ps in s_positions, p in s_piles[ps], t in s_periods[2:end]],
        B_PILE_DONE[ps,p,t] <= B_PILE_DONE[ps,p,t-1] + B_PILE_END_RECLAIMING[ps,p,t-1]
    )
    
    # Piles have a natural ordering: Px can only start BUILDING if P(x-1) is DONE
    for t in s_periods[2:end], ps in s_positions, (prev_p, p) in zip(s_piles[ps][1:end-1], s_piles[ps][2:end])
        @constraint(model, B_PILE_BUILDING[ps,p,t] <= B_PILE_DONE[ps,prev_p,t])
    end

end