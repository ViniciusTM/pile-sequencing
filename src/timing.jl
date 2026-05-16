
function add_timing_constraints!(model::Model, data::Data)

    @unpack s_piles, s_positions, s_periods = data
    @unpack m_local_arrival, m_input_capacity, d_quality_assertion_setup = data
    
    D_BUILDING = model[:D_BUILDING]
    M_LOCAL_TO_POSITION = model[:M_LOCAL_TO_POSITION]
    M_TO_POSITION = model[:M_TO_POSITION]
    D_RECLAIMING = model[:D_RECLAIMING]
    D_QUALITY_ASSERTION = model[:D_QUALITY_ASSERTION]
    B_POSITION_END_BUILDING = model[:B_POSITION_END_BUILDING]

    # Duration constraint
    @constraint(model, [ps in s_positions, p in s_piles[ps], t in s_periods],
        D_BUILDING[ps,t] + D_QUALITY_ASSERTION[ps,t] + D_RECLAIMING[ps,t] <= 24
    )

    # Var time building = max(D_LOCAL_TO_POSITION, D_TO_POSITION)
    @constraint(model, [ps in s_positions, t in s_periods],
        D_BUILDING[ps,t] >= (M_LOCAL_TO_POSITION[ps,t] / m_local_arrival[t]) * 24
    )
    @constraint(model, [ps in s_positions, t in s_periods],
        D_BUILDING[ps,t] >= (M_TO_POSITION[ps,t] / m_input_capacity[ps]) * 24
    )

    # When a pile finishes building on a position, quality assertion must happen until the next day
    @constraint(model, [ps in s_positions, t in s_periods[1:end-1]],
        D_QUALITY_ASSERTION[ps,t] + D_QUALITY_ASSERTION[ps,t+1] >= d_quality_assertion_setup[ps] * B_POSITION_END_BUILDING[ps,t]
    )

end