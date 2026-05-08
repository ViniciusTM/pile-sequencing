# Stockpile Sequencing for a Pellet Plant Blending Yard

> **Work in Progress** — This is an active research project. The model is functional but under development.

A mixed-integer linear programming (MILP) model for tactical planning of stockpile sequencing in an iron ore pelletizing complex.

## Overview

A coastal pelletizing complex processes iron ore pellet feed from multiple sources into pellets for the steelmaking market. Before pelletizing, material goes through a **blending yard** where it is deposited into longitudinal stockpiles that act as buffer storage and chemical homogenization.

This model solves the **tactical planning problem**: given a horizon (typically one month), determine:
- When and where to build each stockpile
- How to blend material from different sources into each pile
- When to reclaim each pile to feed the pelletizing lines
- When each train should arrive

The solution must respect physical infrastructure limits, daily line demands, chemical specification windows, and operational rules governing the pile lifecycle.

## Quick Start

### Prerequisites
- Julia 1.9 or later

### Installation

```bash
git clone https://github.com/your-username/pile-sequencing.git
cd pile-sequencing
julia --project -e 'using Pkg; Pkg.instantiate()'
```

### Running

```bash
julia --project run.jl
```

This runs the toy instance and prints the solution.

## Documentation

- [Problem Description](docs/problem.md) — Full context, physical layout, and business rules
- [Mathematical Formulation](docs/formulation.md) — Sets, variables, constraints, and objective
- [Creating Instances](docs/instances.md) — How to define new problem instances

## Project Structure

```
pile-sequencing/
├── run.jl                    # Entry point
├── src/
│   ├── data.jl               # Data structures
│   ├── variables.jl          # Decision variables and expressions
│   ├── pile_lifecycle.jl     # State machine constraints
│   ├── material_flow.jl      # Flow conservation and capacity
│   ├── quality.jl            # Chemical specification constraints
│   ├── objective.jl          # Objective function
│   └── model.jl              # Model builder and solver
└── instances/
    └── toy_instance.jl       # Example instance
```

## Dependencies

- [JuMP](https://jump.dev/) — Mathematical optimization modeling
- [HiGHS](https://highs.dev/) — Open-source MILP solver
- [Parameters.jl](https://github.com/mauro3/Parameters.jl) — Struct utilities

## Roadmap

**Model enhancements:**
- [ ] Sub-day transitions (quality assay ~6-12h, setup time ~6-12h, same-day phase changes with reduced capacity)
- [ ] Line-level safety stock constraints
- [ ] Shared equipment capacity constraints (stacker/reclaimer per yard)
- [ ] Cost-based objective function

**Infrastructure:**
- [ ] Test with larger, realistic instances
- [ ] Computational experiments and analysis
- [ ] Input data from files (JSON/CSV)
- [ ] Solution export to standard formats

*This research may evolve into an academic paper.*

## License

MIT License — see [LICENSE](LICENSE) file.
