function toy_instance()::Data
    n_periods = 14
    s_compounds = [:Fe, :SiO2, :Al2O3, :P]

    s_positions = [:PS1, :PS2, :PS3]
    k_position_line = Dict(
        :PS1 => :BF1,
        :PS2 => :BF1,
        :PS3 => :BF1
    )

    m_position_min = Dict(:PS1 => 20.0, :PS2 => 20.0, :PS3 => 20.0)
    m_position_max = Dict(:PS1 => 26.0, :PS2 => 26.0, :PS3 => 26.0)
    m_input_capacity = Dict(:PS1 => 7.0, :PS2 => 7.0, :PS3 => 7.0)

    s_lines = [:BF1]
    m_line_demand = Dict(
        (:BF1,1 ) => 0.0, (:BF1,2 ) => 0.0, (:BF1,3 ) => 0.0, (:BF1,4 ) => 0.0, (:BF1,5 ) => 9.0, (:BF1,6 ) => 9.0, (:BF1,7 ) => 9.0, 
        (:BF1,8 ) => 9.0, (:BF1,9 ) => 9.0, (:BF1,10) => 9.0, (:BF1,11) => 9.0, (:BF1,12) => 9.0, (:BF1,13) => 9.0, (:BF1,14) => 9.0, 
    )
    p_line_quality_min = Dict(
        (:Fe, :BF1) => 64.0,
        (:SiO2, :BF1) => 1.0,
        (:Al2O3, :BF1) => 0.3,
        (:P, :BF1) => 0.02
    )
    p_line_quality_max = Dict(
        (:Fe,:BF2) => 67.5,
        (:SiO2,:BF2) => 4.5,
        (:Al2O3,:BF2) => 1.5,
        (:P,:BF2) => 0.07
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
        n_periods=n_periods,
        s_compounds=s_compounds,
        s_positions=s_positions,
        k_position_line=k_position_line,
        m_position_min=m_position_min,
        m_position_max=m_position_max,
        m_input_capacity=m_input_capacity,
        s_lines=s_lines,
        m_line_demand=m_line_demand,
        p_line_quality_min=p_line_quality_min,
        p_line_quality_max=p_line_quality_max,
        m_local_arrival=m_local_arrival,
        p_local_quality=p_local_quality,
        n_trains=n_trains,
        m_train=m_train,
        p_train_quality=p_train_quality,
        t_train_window_start=t_train_window_start,
        t_train_window_end=t_train_window_end,
        n_trains_per_period_max=n_trains_per_period_max
    )

end