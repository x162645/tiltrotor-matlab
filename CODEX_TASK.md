# CODEX_TASK.md

STATUS: COMPLETE / CONTROL ALLOCATION METHOD PACKET / HOLD

Branch: `planning/control-allocation-method`

Base branch: `main`

## Purpose

Prepare the literature-grounded, token-efficient method packet for priority item 3: the open-loop longitudinal pitch-actuator allocation constraint used to close conversion-mode trim.

The durable method file is:

```text
docs/ebook_packets/CONTROL_ALLOCATION_PACKET.md
```

## Priority status

1. `RH_mass/RH_hub` behavior-preserving split: **COMPLETE AND MERGED** in PR #8.
2. General mode-dependent trim core: **COMPLETE AND MERGED** in PR #13.
3. Open-loop pitch-actuator allocation constraint: **NEXT IMPLEMENTATION TARGET; METHOD PACKET READY**.
4. Trim credibility diagnostics.
5. Linearization credibility diagnostics.
6. Robust induced-velocity residual/root solution.

Do not skip directly to items 4-6 until item 3 is implemented and reviewed.

## Decisions fixed by this packet

- The work remains open-loop actuator allocation for trim, not flight-control-law design.
- The electronic-book cosine example is selected as the first conceptual schedule.
- Current code angle convention is used:
  - `betaM=0` helicopter;
  - `betaM=pi/2` airplane.
- Schedule gains are:

```text
gCyclic  = cos(betaM)^2
gElevator = sin(betaM)^2
```

- Existing cyclic and elevator limit magnitudes are used only as dimensionless normalization references.
- The explicit algebraic residual is:

```text
pitchAllocation = gElevator*(cyclicLong/cyclicReference)
                - gCyclic*(elevator/elevatorReference)
```

- `conversion_longitudinal` has four unknowns and four explicit residuals:

```text
unknowns  = theta, collective, cyclicLong, elevator
residuals = udot, wdot, qdot, pitchAllocation
```

- Positive cyclic and positive elevator commands are treated as the same current-model longitudinal command direction. A light endpoint sign audit must verify this before implementation proceeds.
- The schedule is classified `ASSUMED_CONCEPT`; it is not an XV-15 mixer.

## Next implementation boundary

After this documentation branch is merged, create a new implementation branch. Codex will:

- extend `trim_general` to support an explicit algebraic allocation residual;
- add the `conversion_longitudinal` definition;
- add a small cosine schedule helper;
- preserve legacy, helicopter, and airplane endpoint results;
- test only static gains, two endpoints, and one 45-degree conversion point;
- avoid GUI, model, parameter, linearization, Jacobian, inflow, SCAS, autopilot, and real mixer work.

Codex must read this packet instead of the full 622-page electronic book.

## Scope of this branch

Documentation only. No MATLAB production file, test, parameter, GUI, service, model equation, solver, control limit, or linearization file is changed.

## Closeout

This branch is complete and remains on HOLD for review. Do not add implementation work here and do not merge without explicit user authorization.
