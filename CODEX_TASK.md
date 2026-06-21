# CODEX_TASK.md

STATUS: COMPLETE / REVISED CONTROL ALLOCATION METHOD / HOLD

Branch: `planning/control-allocation-method-v2`

Base branch: `main`

## Current priority mainline

1. `RH_mass/RH_hub` split: COMPLETE AND MERGED.
2. General mode-dependent trim core: COMPLETE AND MERGED.
3. Open-loop pitch-actuator allocation: CURRENT TARGET; REVISED METHOD READY.
4. Trim credibility diagnostics.
5. Linearization credibility diagnostics.
6. Robust induced-velocity root solution.

Do not start items 4-6 before item 3 is implemented, tested, reviewed, and merged.

## Purpose of this branch

Replace the superseded four-unknown/four-residual proposal with a method that directly follows the electronic-book mixer architecture.

The durable method file is:

```text
docs/ebook_packets/CONTROL_ALLOCATION_PACKET.md
```

## Fixed technical route

- Keep the aircraft plant at direct actuator level.
- Add a trim-layer normalized virtual open-loop input `pitchCommand`.
- Map it to direct actuators with a conceptual cosine schedule:

```text
gCyclic   = cos(betaM)^2
gElevator = sin(betaM)^2
```

- Generate:

```text
cyclicLong = cyclicDirection*gCyclic*cyclicReference*pitchCommand
elevator   = elevatorDirection*gElevator*elevatorReference*pitchCommand
```

- Define `conversion_longitudinal` with:

```text
unknowns  = theta, collective, pitchCommand
residuals = udot, wdot, qdot
```

- Do not make `cyclicLong` and `elevator` simultaneous independent trim unknowns.
- Do not add a fourth allocation residual.
- Classify the schedule as `ASSUMED_CONCEPT`, not an XV-15 mixer.

## Mandatory gate before implementation

The future Codex task must first run a read-only sign/authority audit at the helicopter endpoint, one 45-degree reference point, and the airplane endpoint. Production-code editing is forbidden until that audit passes.

If control direction changes sign or a required channel has no usable authority, Codex must stop and report. It may not flip signs or tune parameters to force convergence.

## Next implementation branch

After this documentation baseline is merged, create a new implementation branch. Codex will be instructed to execute:

1. baseline regression;
2. read-only sign/authority audit;
3. pure schedule helper and definition changes only if the audit passes;
4. endpoint equivalence tests;
5. one 45-degree conversion trim;
6. one total regression.

## Scope of this branch

Documentation only. No MATLAB production code, tests, parameters, model equations, GUI, services, solver settings, limits, linearization, or inflow code are changed.

## Closeout

This branch remains on HOLD for review. Do not add implementation code and do not merge without explicit user authorization.
