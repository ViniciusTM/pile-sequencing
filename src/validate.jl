
function validate_solution(data::Data, model::Model; tol=1e-5)

    violations = String[]

    append!(violations, validate_arrival_mass(data, model, tol))
    append!(violations, validate_demand_mass(data, model, tol))
    append!(violations, validate_pile_lifecycle(data, model, tol))
    append!(violations, validate_train_allocation(data, model, tol))
    append!(violations, validate_trains_per_period(data, model, tol))
    append!(violations, validate_input_capacity(data, model, tol))
    append!(violations, validate_pile_quality(data, model, tol))
    append!(violations, validate_single_pile_building(data, model, tol))
    append!(violations, validate_single_pile_reclaiming(data, model, tol))
    append!(violations, validate_pile_ordering(data, model, tol))
    append!(violations, validate_timing(data, model, tol))

    if !isempty(violations)
        @warn "Invalid solution found:" violations
    end

end

function validate_arrival_mass(data::Data, model::Model, tol::Float64)

    violations = String[]

    @unpack s_periods, m_local_arrival = data
    M_LOCAL_TO_PILE = value.(model[:M_LOCAL_TO_PILE])

    for t in s_periods
        allocated_mass = sum(M_LOCAL_TO_PILE[:,:,t])
        expected = m_local_arrival[t]
        if !isapprox(allocated_mass, expected; atol=tol)
            push!(violations, "Period $t: allocated mass=$allocated_mass, expected=$expected")
        end
    end

    return violations
end

function validate_demand_mass(data::Data, model::Model, tol::Float64)

    violations = String[]

    @unpack s_lines, s_positions, s_piles, s_periods, m_line_demand, s_line_positions = data
    M_PILE_TO_LINE = value.(model[:M_PILE_TO_LINE])

    for l in s_lines, t in s_periods
        allocated_mass = sum(M_PILE_TO_LINE[ps,p,t] for ps in s_line_positions[l] for p in s_piles[ps])
        expected = m_line_demand[l,t]
        if allocated_mass > expected + tol
            push!(violations, "Line $l, Period $t: allocated mass=$allocated_mass exceeds demand=$expected")
        end
    end

    return violations
end

function validate_pile_lifecycle(data::Data, model::Model, tol::Float64)

    violations = String[]

    M_TO_PILE = value.(model[:M_TO_PILE])
    M_PILE_TO_LINE = value.(model[:M_PILE_TO_LINE])

    for ps in data.s_positions, p in data.s_piles[ps]
        status = :EMPTY
        pile_current_mass = 0.0
        for t in data.s_periods
            inflow = M_TO_PILE[ps,p,t]
            outflow = M_PILE_TO_LINE[ps,p,t]

            if status == :EMPTY
                (outflow > tol) && (push!(violations, "Pile $ps-$p, Period $t: Outflow=$outflow in non-reclaiming period"))
                (inflow > tol) && (status = :BUILDING)

                pile_current_mass += inflow
                if (pile_current_mass > data.m_position_max[ps] + tol)
                    push!(violations, "Pile $ps-$p, Period $t: Mass=$pile_current_mass above maximum=$(data.m_position_max[ps])")
                end
                continue
            end
            if status == :BUILDING
                pile_current_mass += inflow
                if (pile_current_mass > data.m_position_max[ps] + tol)
                    push!(violations, "Pile $ps-$p, Period $t: Mass=$pile_current_mass above maximum=$(data.m_position_max[ps])")
                end

                if outflow > tol
                    (pile_current_mass >= data.m_position_min[ps] - tol) || (
                        push!(violations, "Pile $ps-$p, Period $t: Turned into reclaiming with mass=$pile_current_mass < minimum=$(data.m_position_min[ps])"))
                    status = :RECLAIMING

                    pile_current_mass -= outflow
                    if pile_current_mass < -tol
                        push!(violations, "Pile $ps-$p, Period $t: Mass=$pile_current_mass below zero")
                    end
                end
                continue
            end
            if status == :RECLAIMING
                (inflow > 0) && (push!(violations, "Pile $ps-$p, Period $t: Inflow=$inflow in reclaiming period"))

                pile_current_mass -= outflow
                if pile_current_mass < -tol
                    push!(violations, "Pile $ps-$p, Period $t: Mass=$pile_current_mass below zero")
                end

                if isapprox(pile_current_mass, 0; atol=tol)
                    status = :EMPTY
                end
            end
            if status == :DONE
                (outflow > tol) && (push!(violations, "Pile $ps-$p, Period $t: Outflow=$outflow after pile is done"))
                (inflow > tol) && (push!(violations, "Pile $ps-$p, Period $t: Inflow=$inflow after pile is done"))
            end
        end
    end

    return violations
end

function validate_train_allocation(data::Data, model::Model, tol::Float64)

    violations = String[]

    @unpack s_trains, s_positions, s_piles, s_periods, s_train_window, m_train = data
    B_TRAIN_TO_PILE = value.(model[:B_TRAIN_TO_PILE])

    for i in s_trains
        allocations = []
        for ps in s_positions, p in s_piles[ps], t in s_train_window[i]
            if B_TRAIN_TO_PILE[i,ps,p,t] > 1 - tol
                push!(allocations, (ps, p, t))
            end
        end

        if length(allocations) == 0
            push!(violations, "Train $i: not allocated to any pile")
        elseif length(allocations) > 1
            push!(violations, "Train $i: allocated to multiple piles: $allocations")
        else
            (ps, p, t) = allocations[1]
            if !(t in s_train_window[i])
                push!(violations, "Train $i: allocated at period $t outside window $(s_train_window[i])")
            end
        end
    end

    return violations
end

function validate_trains_per_period(data::Data, model::Model, tol::Float64)

    violations = String[]

    @unpack s_trains, s_positions, s_piles, s_periods, s_train_window, n_trains_per_period_max = data
    B_TRAIN_TO_PILE = value.(model[:B_TRAIN_TO_PILE])

    for t in s_periods
        trains_in_period = 0
        for i in s_trains
            if t in s_train_window[i]
                for ps in s_positions, p in s_piles[ps]
                    if B_TRAIN_TO_PILE[i,ps,p,t] > 1 - tol
                        trains_in_period += 1
                    end
                end
            end
        end
        if trains_in_period > n_trains_per_period_max[t]
            push!(violations, "Period $t: $trains_in_period trains exceed maximum $(n_trains_per_period_max[t])")
        end
    end

    return violations
end

function validate_input_capacity(data::Data, model::Model, tol::Float64)

    violations = String[]

    @unpack s_positions, s_piles, s_periods, m_input_capacity = data
    M_TO_PILE = value.(model[:M_TO_PILE])

    for ps in s_positions, t in s_periods
        total_input = sum(M_TO_PILE[ps,p,t] for p in s_piles[ps])
        if total_input > m_input_capacity[ps] + tol
            push!(violations, "Position $ps, Period $t: input=$total_input exceeds capacity=$(m_input_capacity[ps])")
        end
    end

    return violations
end

function validate_pile_quality(data::Data, model::Model, tol::Float64)

    violations = String[]

    @unpack s_positions, s_piles, s_periods, s_trains, s_compounds = data
    @unpack s_train_window, m_train, p_local_quality, p_train_quality = data
    @unpack p_line_quality_min, p_line_quality_max, k_position_line = data

    M_LOCAL_TO_PILE = value.(model[:M_LOCAL_TO_PILE])
    B_TRAIN_TO_PILE = value.(model[:B_TRAIN_TO_PILE])

    for ps in s_positions, p in s_piles[ps]
        line = k_position_line[ps]

        total_mass = 0.0
        comp_mass = Dict(q => 0.0 for q in s_compounds)

        for t in s_periods
            local_mass = M_LOCAL_TO_PILE[ps,p,t]
            total_mass += local_mass
            for q in s_compounds
                comp_mass[q] += local_mass * p_local_quality[q,t] / 100
            end

            for i in s_trains
                if t in s_train_window[i] && B_TRAIN_TO_PILE[i,ps,p,t] > 1 - tol
                    train_mass = m_train[i]
                    total_mass += train_mass
                    for q in s_compounds
                        comp_mass[q] += train_mass * p_train_quality[i,q] / 100
                    end
                end
            end
        end

        if total_mass < tol
            continue
        end

        for q in s_compounds
            actual_pct = comp_mass[q] / total_mass * 100
            min_pct = p_line_quality_min[line, q]
            max_pct = p_line_quality_max[line, q]

            if actual_pct < min_pct - tol
                push!(violations, "Pile $ps-$p, Compound $q: quality=$(round(actual_pct,digits=2))% below min=$(min_pct)%")
            end
            if actual_pct > max_pct + tol
                push!(violations, "Pile $ps-$p, Compound $q: quality=$(round(actual_pct,digits=2))% above max=$(max_pct)%")
            end
        end
    end

    return violations
end

function validate_single_pile_building(data::Data, model::Model, tol::Float64)

    violations = String[]

    @unpack s_positions, s_piles, s_periods = data
    M_TO_PILE = value.(model[:M_TO_PILE])

    for ps in s_positions, t in s_periods
        piles_building = Symbol[]
        for p in s_piles[ps]
            if M_TO_PILE[ps,p,t] > tol
                push!(piles_building, p)
            end
        end
        if length(piles_building) > 1
            push!(violations, "Position $ps, Period $t: multiple piles building: $piles_building")
        end
    end

    return violations
end

function validate_single_pile_reclaiming(data::Data, model::Model, tol::Float64)

    violations = String[]

    @unpack s_lines, s_positions, s_piles, s_periods, s_line_positions = data
    M_TO_PILE = value.(model[:M_TO_PILE])
    M_PILE_TO_LINE = value.(model[:M_PILE_TO_LINE])

    for l in s_lines, t in s_periods
        # Pilhas terminando (END_RECLAIMING): consumindo e massa restante ≈ 0
        piles_end_reclaiming = Tuple{Symbol,Symbol}[]
        # Pilhas continuando (RECLAIMING): consumindo e massa restante > 0
        piles_reclaiming = Tuple{Symbol,Symbol}[]

        for ps in s_line_positions[l], p in s_piles[ps]
            outflow = M_PILE_TO_LINE[ps,p,t]
            if outflow > tol
                mass_in = sum(M_TO_PILE[ps,p,t2] for t2 in 1:t)
                mass_out = sum(M_PILE_TO_LINE[ps,p,t2] for t2 in 1:t)
                mass_remaining = mass_in - mass_out

                if mass_remaining < tol
                    push!(piles_end_reclaiming, (ps, p))
                else
                    push!(piles_reclaiming, (ps, p))
                end
            end
        end

        if length(piles_reclaiming) > 1
            push!(violations, "Line $l, Period $t: multiple piles in RECLAIMING state: $piles_reclaiming")
        end
        if length(piles_end_reclaiming) > 1
            push!(violations, "Line $l, Period $t: multiple piles in END_RECLAIMING state: $piles_end_reclaiming")
        end
    end

    return violations
end

function validate_pile_ordering(data::Data, model::Model, tol::Float64)

    violations = String[]

    @unpack s_positions, s_piles, s_periods = data
    M_TO_PILE = value.(model[:M_TO_PILE])
    M_PILE_TO_LINE = value.(model[:M_PILE_TO_LINE])

    for ps in s_positions
        piles = s_piles[ps]
        if length(piles) <= 1
            continue
        end

        for (idx, p) in enumerate(piles[2:end])
            prev_p = piles[idx]

            prev_pile_done = false

            for t in s_periods
                prev_mass_remaining = sum(M_TO_PILE[ps,prev_p,t2] for t2 in 1:t) - sum(M_PILE_TO_LINE[ps,prev_p,t2] for t2 in 1:t)

                if prev_mass_remaining < tol && sum(M_PILE_TO_LINE[ps,prev_p,t2] for t2 in s_periods) > tol
                    prev_pile_done = true
                end

                if M_TO_PILE[ps,p,t] > tol && !prev_pile_done
                    push!(violations, "Position $ps: Pile $p started building at period $t before pile $prev_p finished")
                    break
                end
            end
        end
    end

    return violations
end

function validate_timing(data::Data, model::Model, tol::Float64)

    violations = String[]

    @unpack s_positions, s_piles, s_periods = data
    @unpack m_local_arrival, m_input_capacity, m_line_demand, k_position_line, d_quality_assertion_setup = data

    M_LOCAL_TO_PILE = value.(model[:M_LOCAL_TO_PILE])
    M_TO_PILE = value.(model[:M_TO_PILE])
    M_PILE_TO_LINE = value.(model[:M_PILE_TO_LINE])

    for ps in s_positions
        line = k_position_line[ps]
        n_periods = length(s_periods)

        d_available = zeros(n_periods)
        is_end_building = falses(n_periods)

        # Calcular tempo disponível para QA em cada período
        for t in s_periods
            m_local = sum(M_LOCAL_TO_PILE[ps,p,t] for p in s_piles[ps])
            m_total = sum(M_TO_PILE[ps,p,t] for p in s_piles[ps])
            m_out = sum(M_PILE_TO_LINE[ps,p,t] for p in s_piles[ps])

            d_building = max(
                m_local_arrival[t] > tol ? (m_local / m_local_arrival[t]) * 24 : 0.0,
                m_input_capacity[ps] > tol ? (m_total / m_input_capacity[ps]) * 24 : 0.0
            )
            d_reclaiming = m_line_demand[line,t] > tol ? (m_out / m_line_demand[line,t]) * 24 : 0.0

            d_available[t] = 24 - d_building - d_reclaiming

            if d_available[t] < -tol
                push!(violations, "Position $ps, Period $t: building+reclaiming=$(round(d_building + d_reclaiming, digits=2))h exceeds 24h")
            end
        end

        # Detectar END_BUILDING: último dia que cada pilha recebeu massa
        for p in s_piles[ps]
            last_inflow_day = 0
            for t in s_periods
                if M_TO_PILE[ps,p,t] > tol
                    last_inflow_day = t
                end
            end
            if last_inflow_day > 0
                is_end_building[last_inflow_day] = true
            end
        end

        for t in s_periods
            if is_end_building[t]
                setup = d_quality_assertion_setup[ps]
                available_now = max(0.0, d_available[t])
                available_next = t < n_periods ? max(0.0, d_available[t+1]) : 24.0

                if available_now + available_next < setup - tol
                    push!(violations, "Position $ps, Period $t: QA setup requires $(setup)h but only $(round(available_now + available_next, digits=2))h available in periods $t-$(t+1)")
                end
            end
        end
    end

    return violations
end
