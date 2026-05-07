
function add_quality_constraints!(model::Model, data::Data)
    @unpack s_positions, s_piles, s_compounds = data
    @unpack p_line_quality_min, p_line_quality_max, k_position_line = data

    M_COMP_PILE = model[:M_COMP_PILE]
    M_PILE_INPUT = model[:M_PILE_INPUT]

    # Linearização dos limite de qualidade 
    @constraint(model, [ps in s_positions, p in s_piles[ps], q in s_compounds],
        M_COMP_PILE[ps,p,q] >= M_PILE_INPUT[ps,p] * (p_line_quality_min[k_position_line[ps],q]/100)
    )
    @constraint(model, [ps in s_positions, p in s_piles[ps], q in s_compounds],
        M_COMP_PILE[ps,p,q] <= M_PILE_INPUT[ps,p] * (p_line_quality_max[k_position_line[ps],q]/100)
    )

end