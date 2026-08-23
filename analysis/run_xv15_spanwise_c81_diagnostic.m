function results = run_xv15_spanwise_c81_diagnostic()
%RUN_XV15_SPANWISE_C81_DIAGNOSTIC
% Isolate the error caused by collapsing spanwise/Mach-dependent C81 data
% into one scalar section-aero parameter set.
%
% This file defines the next diagnostic layer after PR68:
% - keep geometry, inflow, trim, and BEMT equations unchanged;
% - keep NASA C81 source unchanged;
% - replace only the scalar equivalent section model with spanwise bins;
% - do not fit to OARF CT/CP/FM.

results = struct();
results.experiment = 'C81_spanwise_vs_scalar_low_order';
results.frozen_items = { ...
    'PR67_geometry', ...
    'PR68_external_OARF_validation', ...
    'same_BEMT_equations', ...
    'no_OARF_parameter_identification'};
results.question = ['How much error is introduced by reducing ' ...
    'CL(alpha,M,r), CD(alpha,M,r) to one scalar section model?'];
results.expected_interpretation = struct( ...
    'small_change', 'spanwise reduction is not dominant', ...
    'large_change', 'spanwise/Mach section collapse is important');

warning('Diagnostic scaffold created. Connect to section-aero BEMT loop before claiming results.');
end
