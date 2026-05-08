# Problem Description

This document provides the full context and business rules for the stockpile sequencing problem.

## 1. Context

A pelletizing complex processes iron ore *pellet feed* from multiple
sources into iron ore pellets for the steelmaking market. The complex
may run multiple pelletizing lines, each with its own chemical
specification window — some lines (e.g., direct reduction) have
significantly tighter windows than others (e.g., blast furnace).

Before pelletizing, the feed goes through a **blending yard**, where
material is deposited into **longitudinal stockpiles** that act both as
buffer storage and as a chemical homogenization mechanism. Each pile
is built up over a few days, rests for quality assay, and is then
reclaimed and sent to its corresponding pelletizing line.

**The core challenge is blending.** The chemical quality of incoming
material varies over time: the local concentrator output fluctuates as
mining fronts advance, and each train may come from a different
supplier or mine with distinct quality characteristics. The planner
must combine these variable-quality streams into piles that meet the
tight specification windows of each pelletizing line.

## 2. The Planning Decision

At each planning cycle (typically one month), the operations team must
answer, at daily granularity:

- **In which yard position will each pile be built, and when?**
- **What blend of ores from different sources will compose each pile?**
- **When will each pile be consumed?** (The pelletizing line is
  determined by the position — each position feeds exactly one line.)
- **On which day should each train arrive, and to which position?**
  Each train must go entirely to a single position.

These decisions must respect the physical infrastructure, the daily
line demand, the chemical specification windows of each line, and
operational rules governing how a pile is built and consumed.

## 3. Physical Layout

### 3.1 Yards and Positions

The blending yard is divided into **positions**, the physical
locations where a pile can be built by a *stacker* and reclaimed by a
*reclaimer*. Positions may be grouped into **yards** that share common
material-handling equipment (e.g., the same stacker/reclaimer).

Yards are physical areas, not extensions of a single line: positions
within the same yard may feed different pelletizing lines depending on
the conveyor topology of the complex. Conversely, positions from
different yards may feed the same line.

Each position:

- Holds at most one pile at a time.
- Has a maximum capacity and an operational floor (the minimum mass
  below which a pile is not considered usable).
- Is physically connected to **a single pelletizing line**, which
  determines the quality window applicable to piles built there.

### 3.2 Pelletizing Lines

Each pelletizing line has a **firm daily demand** that must be met
without fail — interrupting a pelletizing line carries significant
operational cost and disrupts contracted production. Lines may produce
different products (e.g., blast furnace pellets vs. direct reduction
pellets), each with its own chemical specification window.

### 3.3 Sources and Inbound Modes

Material reaches the yard through two modes with very different
characteristics:

- **Local concentrator (slurry pipeline / conveyor):** continuous
  flow from the company's own concentration plant. Daily mass and
  chemical quality arrive as **input parameters** of the problem,
  varying along the horizon as a reflection of operational reality
  (planned maintenance, evolving mining fronts, throughput
  fluctuations). The pellet plant adapts to what the concentrator
  delivers; it is not a planning decision.

- **Trains (rail corridor from remote mines):** **discrete,
  indivisible** arrivals. The horizon includes a fixed set of trains,
  each carrying cargo from a specific source (mine A, mine B, ...)
  with fixed mass and a quality assay certified per train. The full
  payload of a train must go to a single position — quality
  traceability prevents splitting a train across destinations. Daily
  rail unloading capacity is bounded by the car-dumper throughput.

The **chemical quality** (Fe, SiO2, Al2O3, P) of every arrival is an
**input parameter**:

- For the concentrator, quality varies day by day along the horizon.
- For each train, quality comes from the loading assay.

The chemical decision in this problem lies in **how to combine these
arrivals into piles**, not in what arrives.

## 4. Pile Lifecycle

A pile goes through three well-defined phases, always in this order:

1. **Building.** Over the course of several days, material is
   deposited into the position (from the concentrator and/or from
   trains) until it reaches the target mass. While building, no line
   reclaims from it.
2. **Ready.** The pile is fully formed and must wait for quality assay
   before it can be consumed. The assay confirms that the blended pile
   meets the specification window of its downstream line.
3. **Reclaiming.** The corresponding pelletizing line draws material
   at a rate dictated by its daily demand, until the pile is fully
   depleted. While being reclaimed, **no new material enters** the
   position.

Additionally, after a pile is fully consumed, there may be a **setup
period** before the position can start building the next pile (for
equipment repositioning or maintenance).

**Sub-day transitions.** Both the quality assay wait and the setup
period are typically shorter than a full day (around 6–12 hours). This
creates a modeling challenge: if a pile finishes building early in the
day, it should ideally be able to start reclaiming later that same day
(with reduced capacity). Similarly, if a pile is fully consumed in the
morning, the next pile could start building that afternoon. Capturing
these sub-day dynamics without exploding the model into hourly periods
is an open challenge.

Several rules follow from this structure:

- **No preemption.** A reclaim is not interrupted to be resumed
  later, and no further material is sent to a position that is already
  being reclaimed. A pile is built, sits ready, gets consumed, and
  only then is the position free again.
- **Minimum mass to start reclaiming.** A pile cannot start being
  consumed before reaching the operational floor.
- **Reclaim empties the position.** When the line finishes consuming
  a pile, the position must reach zero mass before another pile can
  be built there.
- **A line reclaims from one pile at a time.** The single exception is
  the transition day: when a pile runs out mid-day, the line may
  start reclaiming from another ready pile in a different position
  connected to the same line, in order to meet that day's demand.

## 5. Quality and Operational Constraints

In addition to the physical and lifecycle rules above:

- **Per-pile quality window.** The resulting chemical composition of
  each pile (mass-weighted average of the qualities of the arrivals
  that built it) must fall within the window of the product fed by
  the downstream line. DR windows are significantly tighter than BF
  windows, particularly on minimum Fe and maximum SiO2+Al2O3.
- **Daily demand per line.** The mass delivered to each line per day
  must match the planned demand exactly — no shortfall, no surplus.
- **Line safety stock.** The total mass available for each pelletizing
  line (summed across all positions that feed it) must stay above a
  minimum threshold, providing robustness against disruptions.
  Positions from different yards may feed the same line, so this
  constraint couples decisions across the physical layout. The maximum
  storage is implicitly bounded by the sum of position capacities.

## 6. What Counts as a Solution

A solution to the problem specifies, for each day of the horizon:

- Which trains arrived that day, and to which position each was sent.
  (Each train goes entirely to a single position.)
- How the local concentrator output was distributed across positions.
- The state of each position that day (building, ready, or
  reclaiming).
- How much each position delivered to its line.

And it does so **feasibly** — respecting all the physical, lifecycle,
operational and quality rules above. Once a feasible solution is
found, it is considered satisfactory; in this stage, the problem does
not seek to optimize cost, fine quality, or any other metric.
