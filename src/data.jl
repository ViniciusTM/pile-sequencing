@with_kw struct Data
    
    n_periods::Int
    s_compounds::Vector{Symbol} = [:Fe, :SiO2, :Al2O3, :P]

    # Positions
    s_positions::Vector{Symbol}
    k_position_line::Dict{Symbol,Symbol} # ∈ s_lines, ∀ ps in s_positions
    m_position_min::Dict{Symbol,Float64} # ∀ ps in s_positions
    m_position_max::Dict{Symbol,Float64} # ∀ ps in s_positions
    m_input_capacity::Dict{Symbol,Float64}  # ∀ ps in s_positions

    # Demand
    s_lines::Vector{Symbol}
    m_line_demand::Dict{Tuple{Symbol,Int},Float64} # ∀ d in Lines, t in 1..n_periods
    p_line_quality_max::Dict{Tuple{Symbol,Symbol},Float64} # ∀ q in Compounds
    p_line_quality_min::Dict{Tuple{Symbol,Symbol},Float64} # ∀ q in Compounds

    # Local arrival
    m_local_arrival::Vector{Float64} # ∀ t in 1..n_periods
    p_local_quality::Dict{Tuple{Symbol,Int},Float64} # ∀ q in Compounds, t in 1..n_periods

    # Train arrival
    n_trains::Int
    m_train::Vector{Float64} # ∀ i in 1..n_trains
    p_train_quality::Dict{Tuple{Int,Symbol},Float64} # ∀ i in 1..n_trains, q in Compounds
    t_train_window_start::Vector{Int} # ∀ i in 1..n_trains
    t_train_window_end::Vector{Int} # ∀ i in 1..n_trains
    n_trains_per_period_max::Vector{Int} # ∀ t in 1..n_periods

    # ------------ Computed values

    s_periods::Base.OneTo{Int} = 1:n_periods 
    s_trains::Base.OneTo{Int} = 1:n_trains 

    # ∀ t in s_periods
    s_train_window::Dict{Int,UnitRange{Int}} = Dict(i => t_train_window_start[i]:t_train_window_end[i] for i in s_trains)

    # ∀ d in s_lines
    s_line_positions::Dict{Symbol,Vector{Symbol}} = Dict(d => [ps for ps in s_positions if k_position_line[ps] == d] for d in s_lines)
    
    # ∀ ps in s_positions
    s_piles::Dict{Symbol,Vector{Symbol}} = generate_piles(
        s_positions, s_periods, m_input_capacity, m_position_min, m_local_arrival, m_train, m_line_demand, k_position_line
    )

end


# Para upper bound: assume que esta posição poderia receber todo o pool
# de trens. Não cortar solução factível é mais importante que apertar o bound.
function generate_piles(s_positions, s_periods, m_input_capacity, m_position_min, m_local_arrival, m_train, m_line_demand, k_position_line)
    s_piles = Dict{Symbol,Vector{Symbol}}()
    for ps in s_positions
        
        train_arrival_left = sum(m_train)
        pile_mass = 0.0
        is_building = true
        d = k_position_line[ps]

        position_piles = [:P1]
        for t in s_periods
            if is_building
                road_input = min(m_input_capacity[ps], m_local_arrival[t])
                train_input = min(m_input_capacity[ps] - road_input, train_arrival_left)
                train_arrival_left -= train_input
                total_input = road_input + train_input
                
                pile_mass += total_input
                if pile_mass >= m_position_min[ps]
                    pile_mass = m_position_min[ps] # trunca no piso para gerar upper bound de pilhas
                    is_building = false
                end
            else
                pile_mass -= m_line_demand[d,t]
                if pile_mass <= 0
                    pile_mass = 0
                    is_building = true
                    name = Symbol("P$(length(position_piles)+1)")
                    push!(position_piles, name)
                end
            end
        end
        s_piles[ps] = position_piles
    end
    return s_piles
end