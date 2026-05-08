# Creating Problem Instances

This guide explains how to define new problem instances for the stockpile sequencing model.

## Data Structure

All instance data is encapsulated in the `Data` struct defined in `src/data.jl`. You create an instance by calling the `Data` constructor with the required parameters.

## Required Parameters

### Planning Horizon

| Parameter | Type | Description |
|-----------|------|-------------|
| `n_periods` | `Int` | Number of days in the planning horizon |

### Positions (Yard Infrastructure)

| Parameter | Type | Description |
|-----------|------|-------------|
| `s_positions` | `Vector{Symbol}` | List of position identifiers (e.g., `[:PS1, :PS2, :PS3]`) |
| `k_position_line` | `Dict{Symbol,Symbol}` | Maps each position to its pelletizing line |
| `m_position_min` | `Dict{Symbol,Float64}` | Operational floor (minimum pile mass) per position |
| `m_position_max` | `Dict{Symbol,Float64}` | Maximum pile capacity per position |
| `m_input_capacity` | `Dict{Symbol,Float64}` | Maximum daily input rate per position |

### Pelletizing Lines (Demand Side)

| Parameter | Type | Description |
|-----------|------|-------------|
| `s_lines` | `Vector{Symbol}` | List of line identifiers (e.g., `[:BF1, :BF2, :DR]`) |
| `m_line_demand` | `Dict{Tuple{Symbol,Int},Float64}` | Demand per line per day `(line, day) => tons` |
| `p_line_quality_min` | `Dict{Tuple{Symbol,Symbol},Float64}` | Min quality spec `(line, compound) => %` |
| `p_line_quality_max` | `Dict{Tuple{Symbol,Symbol},Float64}` | Max quality spec `(line, compound) => %` |

### Local Arrivals (Concentrator)

| Parameter | Type | Description |
|-----------|------|-------------|
| `m_local_arrival` | `Vector{Float64}` | Daily mass from local concentrator (length = `n_periods`) |
| `p_local_quality` | `Dict{Tuple{Symbol,Int},Float64}` | Quality per compound per day `(compound, day) => %` |

### Train Arrivals (Rail)

| Parameter | Type | Description |
|-----------|------|-------------|
| `n_trains` | `Int` | Number of trains in the horizon |
| `m_train` | `Vector{Float64}` | Mass per train (length = `n_trains`) |
| `p_train_quality` | `Dict{Tuple{Int,Symbol},Float64}` | Quality per train per compound `(train_id, compound) => %` |
| `t_train_window_start` | `Vector{Int}` | Earliest arrival day per train |
| `t_train_window_end` | `Vector{Int}` | Latest arrival day per train |
| `n_trains_per_period_max` | `Vector{Int}` | Max trains per day (length = `n_periods`) |

## Chemical Compounds

The model tracks four compounds by default:
- `:Fe` - Iron content
- `:SiO2` - Silicon dioxide
- `:Al2O3` - Aluminum oxide
- `:P` - Phosphorus

You can customize this via `s_compounds` parameter if needed.

## Example: Toy Instance

Here's a simplified example (see `instances/toy_instance.jl` for full code):

```julia
function my_instance()::Data
    n_periods = 14  # 2-week horizon

    # 3 positions, all serving BF1 line
    s_positions = [:PS1, :PS2, :PS3]
    k_position_line = Dict(:PS1 => :BF1, :PS2 => :BF1, :PS3 => :BF1)

    # Position capacities
    m_position_min = Dict(:PS1 => 20.0, :PS2 => 20.0, :PS3 => 20.0)
    m_position_max = Dict(:PS1 => 26.0, :PS2 => 26.0, :PS3 => 26.0)
    m_input_capacity = Dict(:PS1 => 7.0, :PS2 => 7.0, :PS3 => 7.0)

    # Single BF line with demand starting day 5
    s_lines = [:BF1]
    m_line_demand = Dict(
        (:BF1, t) => (t >= 5 ? 9.0 : 0.0) for t in 1:n_periods
    )

    # Quality specifications for BF pellets
    p_line_quality_min = Dict(
        (:BF1, :Fe) => 64.0, (:BF1, :SiO2) => 1.0,
        (:BF1, :Al2O3) => 0.3, (:BF1, :P) => 0.02
    )
    p_line_quality_max = Dict(
        (:BF1, :Fe) => 67.5, (:BF1, :SiO2) => 4.5,
        (:BF1, :Al2O3) => 1.5, (:BF1, :P) => 0.07
    )

    # Constant local arrival: 7 tons/day
    m_local_arrival = fill(7.0, n_periods)

    # Constant local quality
    p_local_quality = Dict(
        (q, t) => val for t in 1:n_periods
        for (q, val) in [(:Fe, 65.75), (:SiO2, 2.75), (:Al2O3, 0.9), (:P, 0.045)]
    )

    # 3 trains, 5 tons each, can arrive any day
    n_trains = 3
    m_train = fill(5.0, n_trains)
    p_train_quality = Dict(
        (i, q) => val for i in 1:n_trains
        for (q, val) in [(:Fe, 65.75), (:SiO2, 2.75), (:Al2O3, 0.9), (:P, 0.045)]
    )
    t_train_window_start = fill(1, n_trains)
    t_train_window_end = fill(n_periods, n_trains)
    n_trains_per_period_max = fill(1, n_periods)

    return Data(
        n_periods=n_periods,
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
```

## Using Your Instance

1. Create a new file in `instances/` (e.g., `instances/my_instance.jl`)
2. Define a function that returns a `Data` object
3. Modify `run.jl` to include and call your instance:

```julia
include("instances/my_instance.jl")

data = my_instance()
model = build_model(data)
solve!(model, data)
```

## Tips

- **Start small:** Test with a few periods and positions before scaling up
- **Quality feasibility:** Ensure that the combination of local and train qualities can produce blends within specification windows
- **Demand timing:** Demand should start after enough time to build at least one pile
- **Train windows:** Wider windows give the solver more flexibility

## Computed Fields

The `Data` struct automatically computes several derived fields:

| Field | Description |
|-------|-------------|
| `s_periods` | Range `1:n_periods` |
| `s_trains` | Range `1:n_trains` |
| `s_train_window` | Dict mapping train ID to arrival window range |
| `s_line_positions` | Dict mapping each line to its positions |
| `s_piles` | Dict mapping each position to its pile IDs (auto-generated) |

The `s_piles` field uses a heuristic to determine an upper bound on the number of piles per position based on input/output rates.
