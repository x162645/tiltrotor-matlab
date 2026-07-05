# XV-15 Public Parameter Profile

## Purpose

`params_xv15_public.m` is an opt-in parameter profile for public XV-15
geometry, mass, rotor speed, airfoil, control-surface maximum-deflection, and
engine-power reference values. It starts from `params_nominal()` and replaces
only fields that are explicit public hard parameters in the cited NASA sources.

This is not a complete XV-15 mathematical model. It does not claim flight-test
validation, and it does not change the default conceptual model, the legacy wing
default, the full-angle opt-in setting, GUI defaults, trim equations, or power
constraint logic.

## Sources

- NASA SP-2000-4517, `The History of the XV-15 Tilt Rotor Research Aircraft`,
  Appendix A, `XV-15 Characteristics`, PDF pp. 156-157, printed pp. 131-132.
- NASA TM-81177, `Wind-Tunnel Tests of the XV-15 Tilt Rotor Aircraft`,
  notation table and summary, PDF pp. 4-6.

## Replaced Public Parameters

| Family | Code field | Public source value | Code value and unit | Notes |
| - | - | -: | -: | - |
| Mass | `P.mass.m` | 13000 lb design gross weight | `5896.70081 kg` | SP-2000-4517 Appendix A |
| Mass reference | `P.mass.emptyActual_kg` | 10083 lb | `4573.58186 kg` | Reference only |
| Mass reference | `P.mass.actualGrossAtEngineStart_kg` | 13248 lb | `6009.19171 kg` | Reference only |
| Mass reference | `P.mass.fuelReference_kg` | 1436 lb | `651.35784 kg` | Reference only |
| Mass reference | `P.mass.researchInstrumentation_kg` | 1148 lb | `520.72524 kg` | Reference only |
| Wing | `P.wing.S` | 169.0 sq ft | `15.70061376 m^2` | Replaces reference area |
| Wing | `P.wing.b` | 32 ft 2 in | `9.8044 m` | Replaces span |
| Wing | `P.wing.c` | 5.25 ft | `1.6002 m` | Replaces chord |
| Wing | `P.wing.airfoil` | NACA 64A223 | `NACA 64A223` | Airfoil label only |
| Wing | `P.wing.sweep` | -6.5 deg | `-0.1134464 rad` | Stored but not yet applied |
| Wing | `P.wing.dihedral` | 2.0 deg | `0.0349066 rad` | Stored but not yet applied |
| Wing | `P.wing.aspectRatioReference` | 6.12 | `6.12` | Reference field |
| Horizontal tail | `P.htail.span` | 12 ft 10 in | `3.9116 m` | Reference geometry |
| Horizontal tail | `P.htail.S` | 50.25 sq ft | `4.66837626 m^2` | Replaces area |
| Horizontal tail | `P.htail.c` | 3 ft 11 in | `1.1938 m` | Replaces chord |
| Horizontal tail | `P.htail.airfoil` | NACA 64A015 | `NACA 64A015` | Airfoil label only |
| Horizontal tail | `P.htail.aspectRatioReference` | 3.27 | `3.27` | Reference field |
| Vertical tail | `P.vtail.SEach` | 50.5 sq ft total | `2.34580276 m^2` each | Stored as half of total area per tail |
| Vertical tail | `P.vtail.c` | 3.72 ft MAC | `1.133856 m` | Mean aerodynamic chord |
| Vertical tail | `P.vtail.airfoil` | NACA 0009 | `NACA 0009` | Airfoil label only |
| Vertical tail | `P.vtail.aspectRatioReference` | 2.33 | `2.33` | Reference field |
| Rotor | `P.rotor.R` | 25.0 ft diameter | `3.81 m` | Radius from diameter/2 |
| Rotor | `P.rotor.Nb` | 3 blades/proprotor | `3` | Blade count |
| Rotor | `P.rotor.chord` | 14.0 in | `0.3556 m` | Constant chord |
| Rotor | `P.rotor.solidityReference` | 0.089 | `0.089` | Reference field |
| Rotor | `P.rotor.diskLoadingReference_lb_ft2` | 13.2 lb/sq ft | `13.2 lb/sq ft` | Kept in source units as label/reference |
| Rotor | `P.rotor.OmegaHelicopter` | 589 rpm | `61.68018 rad/s` | Reference schedule value |
| Rotor | `P.rotor.OmegaAirplane` | 517 rpm | `54.13913 rad/s` | Reference schedule value |
| Rotor | `P.rotor.Omega` | current model single speed | `P.rotor.OmegaHelicopter` | Keeps current single-speed interface runnable |
| Rotor | `P.rotor.twistGeometricSpinnerToTip` | 36 deg | `0.6283185 rad` | Stored, not mapped to `twistTip` |
| Rotor | `P.rotor.delta3` | -15 deg | `-0.2617994 rad` | Reference field |
| Powerplant | `P.powerplant.engineModel` | Lycoming LTC1K-4K modified T53-L-13B | char label | Reference only |
| Powerplant | `P.powerplant.engineCount` | 2 | `2` | Reference only |
| Powerplant | `P.powerplant.contingencyPower_shp` | 1802 SHP | `1802 shp` | Reference only |
| Powerplant | `P.powerplant.takeoffPower_shp` | 1550 SHP | `1550 shp` | Reference only |
| Powerplant | `P.powerplant.maxContinuousPower_shp` | 1250 SHP | `1250 shp` | Reference only |
| Powerplant | `P.powerplant.helicopterModeTransmissionLimit_shp` | 1160 SHP | `1160 shp` | Reference only |
| Control | `P.control.flapMax` | 75 deg | `1.30899694 rad` | Added reference field |
| Control | `P.control.flaperonMax` | 47 deg | `0.82030475 rad` | Added reference field; does not overwrite `aileronLim` |
| Nacelle | `P.nacelle.sourceAngleConvention` | 90 deg helicopter, 0 deg airplane | char label | Source convention |
| Nacelle | `P.nacelle.modelAngleConvention` | code betaM convention | char label | Code convention remains unchanged |
| Nacelle | `P.nacelle.rateNormal` | 7.5 deg/s | `0.13089969 rad/s` | Reference field |
| Nacelle | `P.nacelle.rateSlow` | 1.5 deg/s | `0.02617994 rad/s` | Reference field |

The wing sweep and dihedral fields are stored as public metadata. The current
aerodynamic force-coordinate calculations do not use these fields yet, so they
are stored but not yet applied.

## Parameters Not Yet Publicly Confirmed

The profile deliberately preserves and marks these fields as concept,
assumed, calibrated, derived from assumed values, or reference-pending:

- Inertia, CG, and moving-nacelle mass: `P.mass.I0`, `P.mass.KI`,
  `P.mass.mNac`, `P.mass.RH_mass`.
- Rotor hub and nacelle geometry: `P.rotor.RH_hub`, `P.rotor.pivotX`,
  `P.rotor.pivotY`, `P.rotor.pivotZ`.
- Blade dynamic parameters: `P.rotor.bladeMass`, `P.rotor.Ib`,
  `P.rotor.Sblade`.
- Wing aerodynamic coefficients and control derivatives:
  `P.wing.CL0`, `P.wing.CLalpha`, `P.wing.CLmax`, `P.wing.CD0`,
  `P.wing.kInduced`, `P.wing.Cm0`, `P.wing.Cmalpha`,
  `P.wing.CLaileron`, `P.wing.Cmaileron`.
- Horizontal-tail position and derivatives: `P.htail.rAC`,
  `P.htail.CLalpha`, `P.htail.CLelevator`, `P.htail.downwashAlpha`,
  `P.htail.incidence`.
- Vertical-tail positions and derivatives: `P.vtail.xAC`, `P.vtail.yAC`,
  `P.vtail.zAC`, `P.vtail.CYbeta`, `P.vtail.CYrudder`.
- SCAS gains, full control mixing laws, complete control derivatives, CG
  envelope, blade mass/inertia data, and dynamic blade parameters.

These fields should wait for primary mass-properties reports, CR-114614, GTRS,
flight manual data, or digitized wind-tunnel/flight-test material before they
are treated as XV-15 values.
