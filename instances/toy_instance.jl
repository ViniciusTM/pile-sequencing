

function toy_instance()::Data
    n_periods = 14

    # Fe, SiO₂, Al₂O₃, P
    s_compounds = [:Fe, :SiO2, :Al2O3, :P]

    s_positions = [:PS1, :PS2, :PS3]
    m_position_min = Dict(:PS1 => 20.0, :PS2 => 20.0, :PS3 => 20.0)
    m_position_max = Dict(:PS1 => 26.0, :PS2 => 26.0, :PS3 => 26.0)
    m_input_capacity = Dict(:PS1 => 7.0, :PS2 => 7.0, :PS3 => 7.0)

    m_line_demand = [
        0.0, 0.0, 0.0, 0.0, 9.0, 9.0, 9.0,
        9.0, 9.0, 9.0, 9.0, 9.0, 9.0, 9.0
    ]
    p_line_quality_min = Dict(
        :Fe => 64.0,
        :SiO2 => 1.0,
        :Al2O3 => 0.3,
        :P => 0.02
    )
    p_line_quality_max = Dict(
        :Fe => 67.5,
        :SiO2 => 4.5,
        :Al2O3 => 1.5,
        :P => 0.07
    )

    m_local_arrival = [
        7.0, 7.0, 7.0, 7.0, 7.0, 7.0, 7.0, 
        7.0, 7.0, 7.0, 7.0, 7.0, 7.0, 7.0
    ]
    p_local_quality = Dict(
        :Fe => [
            65.75, 65.75, 65.75, 65.75, 65.75, 65.75, 65.75,
            65.75, 65.75, 65.75, 65.75, 65.75, 65.75, 65.75
        ],
        :SiO2 => [
            2.75, 2.75, 2.75, 2.75, 2.75, 2.75, 2.75,
            2.75, 2.75, 2.75, 2.75, 2.75, 2.75, 2.75
        ],
        :Al2O3 => [
            0.9, 0.9, 0.9, 0.9, 0.9, 0.9, 0.9,
            0.9, 0.9, 0.9, 0.9, 0.9, 0.9, 0.9
        ],
        :P => [
            0.045, 0.045, 0.045, 0.045, 0.045, 0.045, 0.045,
            0.045, 0.045, 0.045, 0.045, 0.045, 0.045, 0.045
        ]
    )

    n_trains = 3
    m_train = [5.0, 5.0, 5.0]
    
    p_train_quality = Dict(
        :Fe => [65.75, 65.75, 65.75],
        :SiO2 => [2.75, 2.75, 2.75],
        :Al2O3 => [0.9, 0.9, 0.9],
        :P => [0.045, 0.045, 0.045]
    )

    t_train_window_start = [1, 1, 1]
    t_train_window_end = [14, 14, 14]
    n_trains_per_period_max = [
        1, 1, 1, 1, 1, 1, 1, 
        1, 1, 1, 1, 1, 1, 1
    ]

    return Data(
        n_periods,
        s_compounds,
        s_positions,
        m_position_min,
        m_position_max,
        m_input_capacity,
        m_line_demand,
        p_line_quality_min,
        p_line_quality_max,
        m_local_arrival,
        p_local_quality,
        n_trains,
        m_train,
        p_train_quality,
        t_train_window_start,
        t_train_window_end,
        n_trains_per_period_max
    )

end