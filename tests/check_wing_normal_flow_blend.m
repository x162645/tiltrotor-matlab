function report = check_wing_normal_flow_blend()
%CHECK_WING_NORMAL_FLOW_BLEND Deprecated compatibility wrapper.
%
% The old near-normal/lift-line branch blend is no longer a production wing
% load path. Keep this entry point for scripts that still call it, but route
% validation to the NUAA Eq. (16)-(22) zone-sum checks.

warning('check_wing_normal_flow_blend:Deprecated', ...
    ['Near-normal branch blending is deprecated diagnostic metadata only; ' ...
     'running check_wing_nuaa_zone_sum instead.']);
report = check_wing_nuaa_zone_sum();
end
