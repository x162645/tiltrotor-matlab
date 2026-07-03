# Full-Angle Database Formal Rebuild

Date: 2026-07-03

This rebuild uses standard NACA 64A223 coordinates generated from the PDAS/NASA TM-X-3069 6A method and replaces the prior TM-88373 text-constrained near-vertical segment with Figure 6a graph digitization.

## Dimensions

- alpha: -180 to 180 deg, 1 deg spacing
- Reynolds: 0.6e6, 1.0e6, 1.4e6
- Mach: 0, 0.10
- symmetric plain flap grid from TM-88373 Figure 6a: 0, 30, 45, 60, 75, 90 deg

## Source Counts

```json
{
  "PERIODIC_CLOSURE": 72,
  "BRIDGE_MODEL": 10386,
  "TM88373_DIGITIZED_GRAPH": 1116,
  "XFOIL": 306,
  "ASSUMED_POSITIVE_DEEP_STALL_MIRROR_UNVALIDATED": 1116
}
```

## TM-88373 Traceability

- PDF: `references/wing_full_angle/NASA_TM_88373.pdf`
- PDF page: 32
- Original page: 28
- Figure: 6a
- Configuration: basic leading edge, 30% chord plain flap, configuration b
- Flap chord definition: report overall-flap-length definition
- Alpha range used from graph: -75 to -105 deg
- Nominal Re: about 1.0e6
- Moment reference: quarter chord
- Artifacts: `data/wing_full_angle/tm88373_digitized/`

Positive deep-stall rows remain mirrored assumptions and are tagged `UNVALIDATED_POSITIVE_DEEP_STALL`. The full-angle production wing currently calls the database at `flapDeg = 0`; other Figure 6a flap curves support the symmetric plain-flap database dimension and sensitivity checks, not differential aileron aerodynamics.
