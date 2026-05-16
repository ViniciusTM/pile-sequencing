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
    d_quality_assertion_setup = Dict(:PS1 => 8, :PS2 => 8, :PS3 => 8)

    s_lines = [:BF1]
    m_line_demand = Dict(
        (:BF1,1 ) => 0.0, (:BF1,2 ) => 0.0, (:BF1,3 ) => 0.0, (:BF1,4 ) => 0.0, (:BF1,5 ) => 9.0, (:BF1,6 ) => 9.0, (:BF1,7 ) => 9.0, 
        (:BF1,8 ) => 9.0, (:BF1,9 ) => 9.0, (:BF1,10) => 9.0, (:BF1,11) => 9.0, (:BF1,12) => 9.0, (:BF1,13) => 9.0, (:BF1,14) => 9.0, 
    )
    p_line_quality_min = Dict(
        (:BF1, :Fe) => 64.0,
        (:BF1, :SiO2) => 1.0,
        (:BF1, :Al2O3) => 0.3,
        (:BF1, :P) => 0.02
    )
    p_line_quality_max = Dict(
        (:BF1, :Fe) => 67.5,
        (:BF1, :SiO2) => 4.5,
        (:BF1, :Al2O3) => 1.5,
        (:BF1, :P) => 0.07
    )

    m_local_arrival = [
        7.0, 7.0, 7.0, 7.0, 7.0, 7.0, 7.0, 
        7.0, 7.0, 7.0, 7.0, 7.0, 7.0, 7.0
    ]
    p_local_quality = Dict(
        (:Fe,   1 ) => 65.75, (:Fe,   2)  => 65.75, (:Fe,   3 ) => 65.75, (:Fe,   4 )  => 65.75, (:Fe, 5 )  => 65.75, (:Fe,   6 ) => 65.75, (:Fe,  7 ) =>  65.75,
        (:Fe,   8 ) => 65.75, (:Fe,   9)  => 65.75, (:Fe,   10) => 65.75, (:Fe,   11)  => 65.75, (:Fe, 12)  => 65.75, (:Fe,   13) => 65.75, (:Fe,  14) =>  65.75,

        (:SiO2, 1 ) => 2.75 , (:SiO2, 2 ) => 2.75 , (:SiO2, 3 ) => 2.75 , (:SiO2, 4 ) => 2.75 , (:SiO2,5 )  => 2.75 , (:SiO2, 6 ) => 2.75 , (:SiO2,7 ) =>  2.75 ,
        (:SiO2, 8 ) => 2.75 , (:SiO2, 9 ) => 2.75 , (:SiO2, 10) => 2.75,  (:SiO2, 11) => 2.75,  (:SiO2,12)  => 2.75 , (:SiO2, 13) => 2.75,  (:SiO2,14) =>  2.75 ,

        (:Al2O3,1 ) => 0.9  , (:Al2O3,2 ) => 0.9  , (:Al2O3,3 ) => 0.9  , (:Al2O3,4 ) => 0.9  , (:Al2O3,5 ) => 0.9  , (:Al2O3,6 ) => 0.9  , (:Al2O3,7 ) => 0.9  , 
        (:Al2O3,8 ) => 0.9  , (:Al2O3,9 ) => 0.9  , (:Al2O3,10) => 0.9  , (:Al2O3,11) => 0.9  , (:Al2O3,12) => 0.9  , (:Al2O3,13) => 0.9  , (:Al2O3,14) => 0.9  , 

        (:P,    1 ) => 0.045, (:P,    2 ) => 0.045, (:P,    3 ) => 0.045, (:P,    4 ) => 0.045, (:P,    5 ) => 0.045, (:P,    6 ) => 0.045, (:P,    7 ) => 0.045, 
        (:P,    8 ) => 0.045, (:P,    9 ) => 0.045, (:P,    10) => 0.045, (:P,    11) => 0.045, (:P,    12) => 0.045, (:P,    13) => 0.045, (:P,    14) => 0.045
    )

    n_trains = 3
    m_train = [5.0, 5.0, 5.0]
    
    p_train_quality = Dict(
        (1,:Fe   ) => 65.75, (2,:Fe   ) => 65.75, (3,:Fe   ) => 65.75, 
        (1,:SiO2 ) => 2.75 , (2,:SiO2 ) => 2.75 , (3,:SiO2 ) => 2.75 ,
        (1,:Al2O3) => 0.9  , (2,:Al2O3) => 0.9  , (3,:Al2O3) => 0.9  ,
        (1,:P    ) => 0.045, (2,:P    ) => 0.045, (3,:P    ) => 0.045,

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
        d_quality_assertion_setup=d_quality_assertion_setup,
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