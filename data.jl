struct Data
    n_periods::Int # param n_periods
    
    materials_set::Vector{Symbol} # set Materials
    positions_set::Vector{Symbol} # set Positions

    road_usage_plan::Dict{Symbol,Float64} # param road_usage_plan{m inMaterial}
    road_daily_min::Dict{Symbol,Vector{Float64}} # param road_daily_min{m in Material, t in 1...n_periods}
    road_daily_max::Dict{Symbol,Vector{Float64}} # param road_daily_max{m in Material, t in 1...n_periods}

    train_size::Dict{Symbol,Float64} # param train_size{m in Material}
    rail_usage_plan::Dict{Symbol,Int} # param rail_usage_plan{m in Material} int
    rail_daily_min::Dict{Symbol,Vector{Int}} # param road_daily_min{m in Material, t in 1...n_periods} int
    rail_daily_max::Dict{Symbol,Vector{Int}} # param road_daily_max{m in Material, t in 1...n_periods} int

    piles_set::Dict{Symbol,Vector{Symbol}} # set Piles{ps in Positions}
    piles_building::Dict{Tuple{Symbol,Symbol},Vector{Bool}} # param pile_building{ps in Positions, p in Piles[ps], t in 1...n_periods} binary
    piles_size::Dict{Tuple{Symbol,Symbol},Float64} # param pile_size{ps in Positions, p in Piles[ps]}
end

function toy_instance()::Data
    n_periods = 14

    materials_set = [:M1, :M2, :M3]
    positions_set = [:PS1, :PS2]

    road_usage_plan = Dict(
        :M1 => 18.7, 
        :M2 => 21.6,
        :M3 => 24.4
    )
    road_daily_min = Dict(
        :M1 => [1.2, 1.2, 1.2, 1.2, 1.2, 0.0, 0.0, 1.2, 1.2, 1.2, 1.2, 1.2, 0.0, 0.0], 
        :M2 => [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
        :M3 => [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    )
    road_daily_max = Dict(
        :M1 => [5.0, 5.0, 5.0, 5.0, 5.0, 0.0, 0.0, 5.0, 5.0, 5.0, 5.0, 5.0, 0.0, 0.0], 
        :M2 => [7.0, 7.0, 0.0, 7.0, 7.0, 1.2, 0.0, 7.0, 7.0, 0.0, 7.0, 7.0, 1.2, 0.0],
        :M3 => [3.2, 3.2, 3.2, 3.2, 3.2, 3.2, 3.2, 3.2, 3.2, 3.2, 3.2, 3.2, 3.2, 3.2]
    )

    train_size = Dict(
        :M1 => 3.1, 
        :M2 => 1.3,
        :M3 => 1.9
    )
    rail_usage_plan = Dict(
        :M1 => 3, 
        :M2 => 5,
        :M3 => 3
    )
    rail_daily_min = Dict(
        :M1 => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 
        :M2 => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        :M3 => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    )
    rail_daily_max = Dict(
        :M1 => [0, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0], 
        :M2 => [0, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1], 
        :M3 => [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3]
    )

    piles_set = Dict(
        :PS1 => [:PS1P1, :PS1P2],
        :PS2 => [:PS2P1, :PS2P2]
    )
    piles_building = Dict(
        (:PS1, :PS1P1) => [true ,true ,true ,false,false,false,false,false,false,false,false,false,false,false],
        (:PS1, :PS1P2) => [false,false,false,false,false,false,false,false,true ,true ,true ,false,false,false],
        (:PS2, :PS2P1) => [false,false,false,false,true ,true ,true ,false,false,false,false,false,false,false],
        (:PS2, :PS2P2) => [false,false,false,false,false,false,false,false,false,false,false,false,true ,true ]
    )

    piles_size = Dict(
        (:PS1, :PS1P1) => 19.79,
        (:PS1, :PS1P2) => 15.15,
        (:PS2, :PS2P1) => 28.52,
        (:PS2, :PS2P2) => 22.74
    )

    return Data(
        n_periods,
        materials_set,
        positions_set,
        road_usage_plan,
        road_daily_min,
        road_daily_max,
        train_size,
        rail_usage_plan,
        rail_daily_min,
        rail_daily_max,
        piles_set,
        piles_building,
        piles_size
    )

end
