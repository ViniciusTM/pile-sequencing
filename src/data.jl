struct Data
    
    n_periods::Int
    s_compounds::Vector{Symbol}

    # Positions
    s_positions::Vector{Symbol}
    m_position_min::Dict{Symbol, Float64} # ∀ ps in s_positions
    m_position_max::Dict{Symbol, Float64} # ∀ ps in s_positions
    m_input_capacity::Dict{Symbol, Float64}

    # Demand
    m_line_demand::Vector{Float64} # ∀ t in 1..n_periods
    p_line_quality_max::Dict{Symbol,Float64} # ∀ q in Compounds
    p_line_quality_min::Dict{Symbol,Float64} # ∀ q in Compounds

    # Local arrival
    m_local_arrival::Vector{Float64} # ∀ t in 1..n_periods
    p_local_quality::Dict{Symbol, Vector{Float64}} # ∀ q in Compounds, t in 1..n_periods

    # Train arrival
    n_trains::Int
    m_train::Vector{Float64} # ∀ i in 1..n_trains
    p_train_quality::Dict{Symbol, Vector{Float64}} # ∀ q in Compounds, i in 1..n_trains
    t_train_window_start::Vector{Int} # ∀ i in 1..n_trains
    t_train_window_end::Vector{Int} # ∀ i in 1..n_trains
    n_trains_per_period_max::Vector{Int} # ∀ t in 1..n_periods

end
