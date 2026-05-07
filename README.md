# Stockpile Sequencing for a Pellet Plant Blending Yard

## 1. Context

A coastal pelletizing complex processes iron ore *pellet feed* from
multiple sources into iron ore pellets for the steelmaking market. The
complex runs dedicated lines for two distinct products: blast furnace
pellets (BF) and direct reduction pellets (DR), each with its own
chemical specification window — the DR window being significantly
tighter.

Before pelletizing, the feed goes through a **blending yard**, where
material is deposited into **longitudinal stockpiles** that act both as
buffer storage and as a chemical homogenization mechanism. Each pile
is built up over a few days, rests for quality assay, and is then
reclaimed and sent to its corresponding pelletizing line.

## 2. The planning decision

At each planning cycle (typically one month), the operations team must
answer, at daily granularity:

- **In which yard position will each pile be built, and when?**
- **What blend of products will compose each pile, and in what
  proportions?**
- **When will each pile be consumed, and by which pelletizing line?**
- **On which day should each train of the horizon arrive?**

These decisions must respect the physical infrastructure, the daily
line demand, the chemical specification windows of each product, and
operational rules governing how a pile is built and consumed.

## 3. Physical layout

### 3.1 Yards and positions

The complex has three blending yards. Each yard is divided into
**positions**, the physical locations where a pile can be built by a
*stacker* and reclaimed by a *reclaimer*. There are around a dozen
positions distributed across the yards.

Yards are physical areas, not extensions of a single line: positions
within the same yard may feed different pelletizing lines depending on
the conveyor topology of the complex.

Each position:

- Holds at most one pile at a time.
- Has a maximum capacity and an operational floor (the minimum mass
  below which a pile is not considered usable).
- Is physically connected to **a single pelletizing line**, which
  determines the quality window applicable to piles built there.

### 3.2 Pelletizing lines

Three lines consume material from the yard: two dedicated to BF and
one dedicated to DR. Each line has a **firm daily demand** that must
be met without fail — interrupting a pelletizing line carries
significant operational cost and disrupts contracted production.

### 3.3 Sources and inbound modes

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

The **chemical quality** (Fe, SiO₂, Al₂O₃, P) of every arrival is an
**input parameter**:

- For the concentrator, quality varies day by day along the horizon.
- For each train, quality comes from the loading assay.

The chemical decision in this problem lies in **how to combine these
arrivals into piles**, not in what arrives.

## 4. Pile life cycle

A pile goes through three well-defined phases, always in this order:

1. **Building.** Over the course of several days, material is
   deposited into the position (from the concentrator and/or from
   trains) until it reaches the target mass. While building, no line
   reclaims from it.
2. **Ready.** The pile is fully formed, has cleared quality assay,
   and is awaiting consumption. It may stay in this state for one or
   more days.
3. **Reclaiming.** The corresponding pelletizing line draws material
   at a rate dictated by its daily demand, until the pile is fully
   depleted. While being reclaimed, **no new material enters** the
   position.

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

## 5. Quality and operational constraints

In addition to the physical and life-cycle rules above:

- **Per-pile quality window.** The resulting chemical composition of
  each pile (mass-weighted average of the qualities of the arrivals
  that built it) must fall within the window of the product fed by
  the downstream line. DR windows are significantly tighter than BF
  windows, particularly on minimum Fe and maximum SiO₂+Al₂O₃.
- **Daily demand per line.** The mass delivered to each line per day
  must match the planned demand exactly — no shortfall, no surplus.
- **Yard safety stock.** The total mass stored in each yard (summed
  across all piles) must stay within a minimum-maximum band,
  providing robustness against disruptions without exceeding physical
  space. Because yards aggregate positions feeding different lines,
  this constraint couples decisions that would otherwise be
  independent.

## 6. What counts as a solution

A solution to the problem specifies, for each day of the horizon:

- Which trains arrived that day.
- How much of each arrival (concentrator and trains) was directed to
  each position.
- The state of each position that day (building, ready, or
  reclaiming).
- How much each position delivered to its line.

And it does so **feasibly** — respecting all the physical, life-cycle,
operational and quality rules above. Once a feasible solution is
found, it is considered satisfactory; in this stage, the problem does
not seek to optimize cost, fine quality, or any other metric.