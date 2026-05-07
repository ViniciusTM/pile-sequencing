using JuMP
using HiGHS

include("src/data.jl")

include("src/variables.jl")
include("src/pile_lifecycle.jl")
include("src/material_flow.jl")
include("src/objective.jl")
include("src/model.jl")

include("instances/toy_instance.jl")

data = toy_instance()
model = build_model(data)
solve!(model)

