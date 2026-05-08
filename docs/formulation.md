# Mathematical Formulation

This document describes the mixed-integer linear programming (MILP) formulation used to solve the stockpile sequencing problem.

## Sets and Indices

| Symbol | Description |
|--------|-------------|
| $\mathcal{T}$ | Set of time periods (days), indexed by $t$ |
| $\mathcal{PS}$ | Set of yard positions, indexed by $ps$ |
| $\mathcal{P}_{ps}$ | Set of piles for position $ps$, indexed by $p$ |
| $\mathcal{L}$ | Set of pelletizing lines, indexed by $\ell$ |
| $\mathcal{I}$ | Set of trains, indexed by $i$ |
| $\mathcal{Q}$ | Set of chemical compounds {Fe, SiO2, Al2O3, P}, indexed by $q$ |
| $\mathcal{W}_i$ | Time window (subset of $\mathcal{T}$) when train $i$ can arrive |

## Parameters

### Infrastructure
| Symbol | Description |
|--------|-------------|
| $\text{line}_{ps}$ | Pelletizing line served by position $ps$ |
| $\underline{M}_{ps}$ | Minimum pile mass (operational floor) at position $ps$ |
| $\overline{M}_{ps}$ | Maximum pile capacity at position $ps$ |
| $\text{cap}_{ps}$ | Maximum daily input rate at position $ps$ |

### Demand and Quality
| Symbol | Description |
|--------|-------------|
| $d_{\ell,t}$ | Daily demand of line $\ell$ at period $t$ |
| $\underline{q}_{\ell,c}$ | Minimum quality spec for compound $c$ on line $\ell$ (%) |
| $\overline{q}_{\ell,c}$ | Maximum quality spec for compound $c$ on line $\ell$ (%) |

### Material Arrivals
| Symbol | Description |
|--------|-------------|
| $a_t^{\text{local}}$ | Local concentrator arrival mass at period $t$ |
| $q_{c,t}^{\text{local}}$ | Quality of compound $c$ in local arrival at period $t$ (%) |
| $m_i$ | Mass of train $i$ |
| $q_{i,c}^{\text{train}}$ | Quality of compound $c$ in train $i$ (%) |
| $\overline{n}_t$ | Maximum number of trains that can arrive at period $t$ |

## Decision Variables

### Material Flow
| Variable | Domain | Description |
|----------|--------|-------------|
| $x_{ps,p,t}^{\text{local}}$ | $\geq 0$ | Local material sent to pile $p$ at position $ps$ on day $t$ |
| $b_{i,ps,p,t}$ | $\{0,1\}$ | 1 if train $i$ is sent to pile $p$ at position $ps$ on day $t$ |
| $y_{ps,p,t}$ | $\geq 0$ | Material reclaimed from pile $p$ at position $ps$ on day $t$ |
| $s_{\ell,t}$ | $\geq 0$ | Demand slack (unmet demand) for line $\ell$ on day $t$ |

### Pile State (Binary)
| Variable | Description |
|----------|-------------|
| $\beta_{ps,p,t}^{\text{empty}}$ | Pile is empty, awaiting material |
| $\beta_{ps,p,t}^{\text{build}}$ | Pile is being built (receiving material) |
| $\beta_{ps,p,t}^{\text{start}}$ | First day of reclaiming |
| $\beta_{ps,p,t}^{\text{cont}}$ | Continuing to reclaim |
| $\beta_{ps,p,t}^{\text{end}}$ | Last day of reclaiming |
| $\beta_{ps,p,t}^{\text{done}}$ | Pile fully consumed |

### Derived Expressions
| Expression | Definition |
|------------|------------|
| $M_{ps,p,t}^{\text{train}}$ | $\sum_{i: t \in \mathcal{W}_i} b_{i,ps,p,t} \cdot m_i$ |
| $M_{ps,p,t}^{\text{in}}$ | $x_{ps,p,t}^{\text{local}} + M_{ps,p,t}^{\text{train}}$ |
| $M_{ps,p}^{\text{total}}$ | $\sum_{t} M_{ps,p,t}^{\text{in}}$ |
| $\beta_{ps,p,t}^{\text{reclaim}}$ | $\beta_{ps,p,t}^{\text{start}} + \beta_{ps,p,t}^{\text{cont}} + \beta_{ps,p,t}^{\text{end}}$ |
| $Q_{ps,p,c}$ | $\sum_t \left( x_{ps,p,t}^{\text{local}} \cdot \frac{q_{c,t}^{\text{local}}}{100} + \sum_{i: t \in \mathcal{W}_i} b_{i,ps,p,t} \cdot m_i \cdot \frac{q_{i,c}^{\text{train}}}{100} \right)$ |

## Objective Function

Minimize total unmet demand:

$$\min \sum_{\ell \in \mathcal{L}} \sum_{t \in \mathcal{T}} s_{\ell,t}$$

## Constraints

### Pile Lifecycle (State Machine)

Each pile must be in exactly one state at any time:
$$\beta_{ps,p,t}^{\text{empty}} + \beta_{ps,p,t}^{\text{build}} + \beta_{ps,p,t}^{\text{reclaim}} + \beta_{ps,p,t}^{\text{done}} = 1 \quad \forall ps, p, t$$

**Initial state:** Piles start either empty or building:
$$\beta_{ps,p,1}^{\text{empty}} + \beta_{ps,p,1}^{\text{build}} = 1 \quad \forall ps, p$$

**State transitions:** Each state can only transition to specific next states. These are enforced by the following constraints for $t > 1$:

EMPTY can only stay EMPTY (once a pile leaves EMPTY, it never returns):
$$\beta_{ps,p,t}^{\text{empty}} \leq \beta_{ps,p,t-1}^{\text{empty}}$$

BUILDING can come from EMPTY or stay BUILDING:
$$\beta_{ps,p,t}^{\text{build}} \leq \beta_{ps,p,t-1}^{\text{build}} + \beta_{ps,p,t-1}^{\text{empty}}$$

START_RECLAIMING can only come from BUILDING (single-day state):
$$\beta_{ps,p,t}^{\text{start}} \leq \beta_{ps,p,t-1}^{\text{build}}$$

CONTINUE_RECLAIMING can come from START or stay CONTINUE:
$$\beta_{ps,p,t}^{\text{cont}} \leq \beta_{ps,p,t-1}^{\text{start}} + \beta_{ps,p,t-1}^{\text{cont}}$$

END_RECLAIMING can come from START or CONTINUE (single-day state):
$$\beta_{ps,p,t}^{\text{end}} \leq \beta_{ps,p,t-1}^{\text{start}} + \beta_{ps,p,t-1}^{\text{cont}}$$

DONE can come from END or stay DONE:
$$\beta_{ps,p,t}^{\text{done}} \leq \beta_{ps,p,t-1}^{\text{done}} + \beta_{ps,p,t-1}^{\text{end}}$$

**Pile ordering:** Pile $p+1$ can only start building after pile $p$ is done:
$$\beta_{ps,p+1,t}^{\text{build}} \leq \beta_{ps,p,t}^{\text{done}} \quad \forall ps, p, t > 1$$

### Material Flow

**Local allocation:** All local material must be directed to some pile:
$$\sum_{ps} \sum_{p \in \mathcal{P}_{ps}} x_{ps,p,t}^{\text{local}} = a_t^{\text{local}} \quad \forall t$$

**Train assignment:** Each train arrives exactly once:
$$\sum_{ps} \sum_{p \in \mathcal{P}_{ps}} \sum_{t \in \mathcal{W}_i} b_{i,ps,p,t} = 1 \quad \forall i$$

**Train capacity:** Maximum trains per day:
$$\sum_{ps} \sum_{p \in \mathcal{P}_{ps}} \sum_{i: t \in \mathcal{W}_i} b_{i,ps,p,t} \leq \overline{n}_t \quad \forall t$$

**Input during building:** Material enters only during BUILDING state:
$$M_{ps,p,t}^{\text{in}} \leq \text{cap}_{ps} \cdot \beta_{ps,p,t}^{\text{build}} \quad \forall ps, p, t$$

**Output during reclaiming:** Material exits only during RECLAIMING states:
$$y_{ps,p,t} \leq d_{\text{line}_{ps},t} \cdot \beta_{ps,p,t}^{\text{reclaim}} \quad \forall ps, p, t$$

**Minimum pile size:** Piles must reach operational floor before reclaiming:
$$M_{ps,p}^{\text{total}} \geq \underline{M}_{ps} \cdot \mathbb{1}[\text{pile used}] \quad \forall ps, p$$

**Maximum pile size:**
$$M_{ps,p}^{\text{total}} \leq \overline{M}_{ps} \quad \forall ps, p$$

**Demand satisfaction:**
$$\sum_{ps: \text{line}_{ps}=\ell} \sum_{p \in \mathcal{P}_{ps}} y_{ps,p,t} = d_{\ell,t} - s_{\ell,t} \quad \forall \ell, t$$

**One active pile per line:** At most one pile in each reclaiming sub-state per line:
$$\sum_{ps: \text{line}_{ps}=\ell} \sum_{p \in \mathcal{P}_{ps}} \beta_{ps,p,t}^{\text{cont}} \leq 1 \quad \forall \ell, t$$

(Similar constraints for START and END states, with allowance for transition days)

### Quality Constraints

Linearized quality bounds using mass of each compound:

**Minimum quality:**
$$Q_{ps,p,c} \geq M_{ps,p}^{\text{total}} \cdot \frac{\underline{q}_{\text{line}_{ps},c}}{100} \quad \forall ps, p, c$$

**Maximum quality:**
$$Q_{ps,p,c} \leq M_{ps,p}^{\text{total}} \cdot \frac{\overline{q}_{\text{line}_{ps},c}}{100} \quad \forall ps, p, c$$

## Model Characteristics

| Aspect | Value |
|--------|-------|
| Problem type | Mixed-Integer Linear Program (MILP) |
| Solver | HiGHS (open-source) |
| Binary variables | Train assignments + pile states |
| Continuous variables | Material flows |
| Key modeling technique | Explicit state machine for pile lifecycle |

## Implementation Notes

- **Pile generation heuristic:** Upper bound on number of piles per position is computed via simulation assuming maximum input rate
- **Quality linearization:** Avoids bilinear terms by tracking compound mass instead of concentration
- **Demand slack:** Allows model to find feasible solutions even when full demand cannot be met

## Current Limitations

The following features described in the problem document are **not yet implemented**:

- **Sub-day transitions:** The model uses daily granularity. If a pile finishes building or reclaiming, the next phase can only start the following day. In reality, quality assay and setup times are around 6–12 hours, so same-day transitions with reduced capacity should be possible.
- **Line safety stock:** No constraint enforces minimum inventory per line.
- **Shared equipment:** Input/output capacity is per-position; shared stacker/reclaimer constraints are not modeled.
