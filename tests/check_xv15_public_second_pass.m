function summary = check_xv15_public_second_pass()
%CHECK_XV15_PUBLIC_SECOND_PASS Verify safe application and interface gates.

P0 = params_nominal();
[P, manifest] = apply_xv15_public_overlay_second_pass(P0);
reference = params_xv15_public_reference_second_pass();

expectedRootCut = 0.0875;
expectedIb = 105*1.3558179483314004;

assert(abs(P.rotor.rootCut-expectedRootCut) < 1e-12, ...
    'XV-15 root-cut ratio was not applied.');
assert(abs(P.rotor.Ib-expectedIb) < 1e-10, ...
    'XV-15 per-blade flapping inertia was not applied.');

% Legacy direct geometry that remains semantically homologous is retained.
assert(abs(P.rotor.R-3.81) < 1e-12, ...
    'Legacy XV-15 rotor radius overlay was unexpectedly lost.');
assert(P.rotor.Nb == 3, ...
    'Legacy XV-15 blade-count overlay was unexpectedly lost.');

% These three source facts are real XV-15 data but are intentionally not
% collapsed into incompatible scalar fields by V2.
assert(isequal(P.rotor.Omega,P0.rotor.Omega), ...
    'V2 must not apply one XV-15 rpm globally.');
assert(isequal(P.rotor.chord,P0.rotor.chord), ...
    'V2 must not collapse radial root/chord geometry to one scalar.');
assert(isequal(P.rotor.twistTip,P0.rotor.twistTip), ...
    'V2 must not map distributed XV-15 twist to the current linear-twist field.');

for path = {'rotor.Omega','rotor.chord','rotor.twistTip'}
    assert(any(strcmp(manifest.blockedLegacyPaths,path{1})), ...
        'Expected blocked legacy path is missing: %s',path{1});
end

safeRecords = reference.records([reference.records.applyToModel]);
safePaths = sort({safeRecords.path});
assert(isequal(safePaths,sort({'rotor.Ib','rotor.rootCut'})), ...
    'Unexpected second-pass record was made auto-applicable.');

omegaRecords = reference.records(strcmp({reference.records.path},'rotor.Omega'));
assert(numel(omegaRecords)==3, ...
    'Expected three documented XV-15 rotor-speed regimes.');
assert(all(~[omegaRecords.applyToModel]), ...
    'Mode-dependent XV-15 rotor speeds must remain interface-blocked.');

summary = struct();
summary.allPassed = true;
summary.safeAppliedPaths = safePaths;
summary.blockedLegacyPaths = manifest.blockedLegacyPaths;
summary.variantName = manifest.variantName;
end
