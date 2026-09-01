# Accepted fine-scale full-A evidence

This directory freezes the **accepted fine-scale (`stepScale = 0.5`) full state Jacobian A blocks** used only for MATLAB-native modal matching reproduction.

Scientific boundary: these matrices are whole-aircraft **propagation/sensitivity evidence for the generic conceptual airframe**, not XV-15 whole-aircraft validation.

## Evidence blocks

Each CSV contains exactly one `9 x 9` A matrix as **81 long-format rows**.

| File | Case | Model | Source artifact | Artifact digest |
| --- | --- | --- | ---: | --- |
| `STAGE2_ACCEPTED_A_B15_M0_SCALE05.csv` | B15_V020 | M0_MATCHED_PRODUCTION | 9781737622 | `sha256:c12863890c26e57a614580df38db7a4a830496ca0592092da002087c7afab57f` |
| `STAGE2_ACCEPTED_A_B15_M1_SCALE05.csv` | B15_V020 | M1_EVIDENCE_V1_PROPAGATION | 9781737622 | `sha256:c12863890c26e57a614580df38db7a4a830496ca0592092da002087c7afab57f` |
| `STAGE2_ACCEPTED_A_B75_M0_SCALE05.csv` | B75_V080 | M0_MATCHED_PRODUCTION | 9781761914 | `sha256:33d7596ee0111e6dd0b3b4ec754ef3399395cdf8fa3ab801cef23376b98d765c` |
| `STAGE2_ACCEPTED_A_B75_M1_SCALE05.csv` | B75_V080 | M1_EVIDENCE_V1_PROPAGATION | 9781761914 | `sha256:33d7596ee0111e6dd0b3b4ec754ef3399395cdf8fa3ab801cef23376b98d765c` |

Together the four blocks contain **324 matrix elements**.

## Why four files instead of one manually assembled snapshot?

An earlier combined file named `STAGE2_ACCEPTED_FULL_A_MATRICES_SCALE05.csv` had the correct structural shape (four 81-row blocks) but did **not** preserve the exact numerical contents of the accepted source artifacts. MATLAB regression exposed the mismatch when the reconstructed M0 eigenvalues could not align with the already frozen accepted modal table. That combined file was therefore removed rather than tolerated or hidden behind a wider numerical threshold.

The files in this directory are copied from the accepted direct-linearization artifact CSVs and retain their artifact IDs and digests row-by-row. The reproduction script concatenates these four exact blocks and validates `4 x 81 = 324`, uniqueness of all matrix indices, finite values, model/case identities, artifact IDs, and digests before eigenanalysis.

## Reproduction

Run:

```matlab
startup;
addpath(fullfile(pwd,'analysis','stage2_aircraft'));
run_stage2_accepted_modal_matching_reproduction;
```

The reproduction performs no trim solve, no new finite differencing, no continuation, and no model/solver parameter changes. It reconstructs the frozen A matrices, computes eigenpairs, collapses conjugate pairs using the positive-imaginary representative, and performs global same-type assignment using:

`normalized eigenvalue distance + (1 - MAC)`

The frozen `STAGE2_ACCEPTED_MODAL_MATCHING.csv` is used only after the independent assignment for ordering and regression validation.
