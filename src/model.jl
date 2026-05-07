
function build_model(data::Data)::Model
    model = Model(HiGHS.Optimizer)
    add_variables!(model, data)
    add_pile_lifecycle_constraints!(model, data)
    add_material_flow_constraints!(model, data)
    add_quality_constraints!(model,data)
    add_objective!(model)
    
    return model
end

function solve!(model::Model, data::Data)
    optimize!(model)
    
    println("Status: ", termination_status(model))
    if has_values(model)
        println("FO: ", value(objective_function(model)))
        check_solution(model, data)
    end

end

function check_solution(model::Model, data::Data)
    
    println()
    println("-"^30)
    println()
    println("Position | Pile | Day: 1  2  3  4  5  6  7  8  9  10 11 12 13 14")
    for ps in data.s_positions, p in data.s_piles[ps]
        print("$(rpad(String(ps), 8)) | $(rpad(String(p), 4)) |      ")
        for t in data.s_periods
            
            if value(model[:B_PILE_BUILDING][ps,p,t]) ≈ 1
                status = "B"
            elseif value(model[:B_PILE_RECLAIMING][ps,p,t]) ≈ 1
                status = "R"
            else
                status = "."
            end
            print(rpad(status,3))
        end
        println()
    end
    println()
    println("-"^30) 
    println()
    println("Periods:  1   |   2    |   3    |   4    |   5    |   6    |   7    |   8    |   9    |   10   |   11   |   12   |   13   |   14   ")
    println("----------------------------------------------------------------------------------------------------------------------------------")
    for ps in data.s_positions
        print(rpad(String(ps),5), ": ")
        for t in data.s_periods
            @printf("% 6.2f | ", sum(value(model[:M_IN_PILE][ps,p,t]) for p in data.s_piles[ps]))
        end
        print("\n---")
        print("\nLOCAL: ")
        for t in data.s_periods
            @printf("% 6.2f | ", sum(value(model[:M_LOCAL_TO_PILE][ps,p,t]) for p in data.s_piles[ps]))
        end
        print("\nRAIL : ")
        for t in data.s_periods
            @printf("% 6.2f | ", sum(value(model[:M_TRAIN_TO_PILE][ps,p,t]) for p in data.s_piles[ps]))
        end
        print("\n---")
        print("\nIN   : ")
        for t in data.s_periods
            @printf("% 6.2f | ", sum(value(model[:M_TO_PILE][ps,p,t]) for p in data.s_piles[ps]))
        end
        print("\nOUT  : ")
        for t in data.s_periods
            @printf("% 6.2f | ", sum(value(model[:M_PILE_TO_LINE][ps,p,t]) for p in data.s_piles[ps]))
        end
        println("\n--------------------------------------------------------------------")
    end
    print("\nLOCAL: ")
    for t in data.s_periods
        @printf("% 6.2f | ", sum(value(model[:M_LOCAL_TO_PILE][ps,p,t]) for ps in data.s_positions for p in data.s_piles[ps]))
    end


    println()
    println("-"^30)
    println()
    for i in data.s_trains
        for (ps,p,t) in eachindex((model[:B_TRAIN_TO_PILE][i,:,:,:]))
            if value.(model[:B_TRAIN_TO_PILE][i,ps,p,t]) ≈ 1
                println("Train $i | Day $t | $ps | $p")
            end
        end
    end

    
    # for (ps,p,q) in eachindex(model[:M_COMP_PILE])
    #     println("$ps, $p, $q", ": ")

    #     m_comp = round(value(model[:M_COMP_PILE][ps,p,q]), digits=3)
    #     m_pile = round(value(model[:M_PILE_INPUT][ps,p]), digits=3)
    #     p_min = round(data.p_line_quality_min[data.k_position_line[ps],q], digits=3)
    #     p_max = round(data.p_line_quality_max[data.k_position_line[ps],q], digits=3)
        
    #     println("$m_comp >= $m_pile * $p_min%")
    #     println("$m_comp >= $(m_pile*p_min/100)")

    #     println("$m_comp <= $m_pile * $p_max%")
    #     println("$m_comp <= $(m_pile*p_max/100)")
    #     println("-------------------------")

    # end

end