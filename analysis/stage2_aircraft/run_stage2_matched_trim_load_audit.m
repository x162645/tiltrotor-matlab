function results = run_stage2_matched_trim_load_audit(outputRoot)
%RUN_STAGE2_MATCHED_TRIM_LOAD_AUDIT Re-evaluate frozen accepted centers only.
%
% No trim optimization, continuation, parameter change, tolerance change,
% bound change, or DOF change is performed here.  The six accepted centers
% are read from the versioned evidence CSV and evaluated directly with the
% matched Stage-2 EOM.  For M1 only, the accepted converged left/right flap
% states are supplied as numerical initial states.

if nargin < 1 || isempty(outputRoot)
    outputRoot = fullfile(pwd,'results','stage2_matched_trim_load_audit');
end
if ~exist(outputRoot,'dir'), mkdir(outputRoot); end

here = fileparts(mfilename('fullpath'));
centerPath = fullfile(here,'evidence','STAGE2_ACCEPTED_MATCHED_TRIM_CENTERS.csv');
centers = readtable(centerPath,'TextType','string');
assert(height(centers)==6,'Stage2MatchedTrimLoad:ExpectedSixAcceptedCenters');
P = stage2_matched_rotor_parameters();

rows = repmat(empty_point_row(),height(centers),1);
for i = 1:height(centers)
    c = center_from_table(centers,i);
    Pk = seed_from_center(P,c);
    [xdot,out] = stage2_tiltrotor_eom(c.modelIdentity,c.x,c.u,c.betaM,Pk);
    residualNorm = norm(xdot([1 3 5]));
    supported = isreal(xdot) && all(isfinite(xdot)) && ...
        logical(out.physicalConverged) && logical(out.physicalBranchSupported);
    reproduced = logical(c.sourceCredible) && supported && residualNorm < P.trim.residualTolerance;
    rows(i) = fill_point_row(c,xdot,out,residualNorm,reproduced,P);
end

points = struct2table(rows,'AsArray',true);
writetable(points,fullfile(outputRoot,'STAGE2_MATCHED_TRIM_LOAD_POINTS.csv'));

caseNames = ["B15_V020";"B45_V035";"B75_V080"];
deltaRows = repmat(empty_delta_row(),numel(caseNames),1);
for i = 1:numel(caseNames)
    idx0 = find(points.caseName==caseNames(i) & points.modelIdentity=="M0_MATCHED_PRODUCTION",1);
    idx1 = find(points.caseName==caseNames(i) & points.modelIdentity=="M1_EVIDENCE_V1_PROPAGATION",1);
    assert(~isempty(idx0)&&~isempty(idx1),'Stage2MatchedTrimLoad:MissingMatchedPair');
    deltaRows(i) = make_delta(points(idx0,:),points(idx1,:));
end

deltas = struct2table(deltaRows,'AsArray',true);
writetable(deltas,fullfile(outputRoot,'STAGE2_MATCHED_TRIM_LOAD_DELTAS.csv'));

summary = table(sum(points.centerReproduced),sum(points.physicalConverged), ...
    sum(points.physicalBranchSupported),sum(deltas.comparable), ...
    'VariableNames',{'ReproducedCenterCount','PhysicalConvergedCount', ...
    'PhysicalBranchSupportedCount','ComparableCaseCount'});
writetable(summary,fullfile(outputRoot,'STAGE2_MATCHED_TRIM_LOAD_SUMMARY.csv'));

metadata = table(["ACCEPTED_CENTERS_ONLY_NO_RETRIM"; ...
    "M1_CARRIES_ACCEPTED_LEFT_RIGHT_FLAP_STATES_ONLY"; ...
    "LONGITUDINAL_RESIDUAL_NORM_Udot_Wdot_Qdot"; ...
    "NO_PHYSICS_PARAMETER_TOLERANCE_BOUND_OR_DOF_CHANGE"; ...
    "WHOLE_AIRCRAFT_PROPAGATION_SENSITIVITY_NOT_XV15_AIRCRAFT_VALIDATION"], ...
    'VariableNames',{'metadataValue'});
writetable(metadata,fullfile(outputRoot,'STAGE2_MATCHED_TRIM_LOAD_METADATA.csv'));

results = struct('centers',centers,'points',points,'deltas',deltas,'summary',summary, ...
    'metadata',metadata,'claimBoundary', ...
    'WHOLE_AIRCRAFT_PROPAGATION_SENSITIVITY_NOT_XV15_AIRCRAFT_VALIDATION');
save(fullfile(outputRoot,'STAGE2_MATCHED_TRIM_LOAD_AUDIT.mat'),'results');
disp(points); disp(deltas); disp(summary);
end

function c = center_from_table(T,i)
c = struct();
c.caseName = char(T.caseName(i));
c.modelIdentity = char(T.modelIdentity(i));
c.mode = char(T.mode(i));
c.centerSource = char(T.centerSource(i));
c.sourceWorkflowRun = T.sourceWorkflowRun(i);
c.sourceArtifactId = T.sourceArtifactId(i);
c.sourceHeadSha = char(T.sourceHeadSha(i));
c.sourceResidualNorm = T.residualNorm(i);
c.sourceCredible = logical(T.credible(i));
c.x = [T.x1_u_mps(i);T.x2_v_mps(i);T.x3_w_mps(i);T.x4_p_rps(i);T.x5_q_rps(i); ...
    T.x6_r_rps(i);T.x7_phi_rad(i);T.x8_theta_rad(i);T.x9_psi_rad(i)];
c.u = [T.u1_collective_rad(i);T.u2_diffCollective_rad(i);T.u3_cyclicLong_rad(i); ...
    T.u4_diffCyclicLong_rad(i);T.u5_aileron_rad(i);T.u6_elevator_rad(i);T.u7_rudder_rad(i)];
c.flapLeft = [T.leftBeta0_rad(i);T.leftBeta1c_rad(i);T.leftBeta1s_rad(i)];
c.flapRight = [T.rightBeta0_rad(i);T.rightBeta1c_rad(i);T.rightBeta1s_rad(i)];
switch c.caseName
    case 'B15_V020', c.betaM = 15*pi/180;
    case 'B45_V035', c.betaM = 45*pi/180;
    case 'B75_V080', c.betaM = 75*pi/180;
    otherwise, error('Stage2MatchedTrimLoad:UnknownCase','Unknown case %s',c.caseName);
end
end

function Pk = seed_from_center(P,c)
Pk = P;
if strcmp(c.modelIdentity,'M1_EVIDENCE_V1_PROPAGATION')
    Pk.stage2Numerics.flapInitialLeft = c.flapLeft(:);
    Pk.stage2Numerics.flapInitialRight = c.flapRight(:);
end
end

function row = fill_point_row(c,xdot,out,residualNorm,reproduced,P)
comp = out.components; L = comp.rotorLeft; R = comp.rotorRight;
row = empty_point_row();
row.caseName = string(c.caseName); row.modelIdentity = string(c.modelIdentity); row.mode = string(c.mode);
row.centerSource = string(c.centerSource); row.sourceWorkflowRun = c.sourceWorkflowRun;
row.sourceArtifactId = c.sourceArtifactId; row.sourceHeadSha = string(c.sourceHeadSha);
row.sourceResidualNorm = c.sourceResidualNorm; row.reevaluatedResidualNorm = residualNorm;
row.residualDelta = residualNorm-c.sourceResidualNorm; row.sourceCredible = c.sourceCredible;
row.centerReproduced = reproduced; row.physicalConverged = logical(out.physicalConverged);
row.physicalBranchSupported = logical(out.physicalBranchSupported); row.physicalStatus = string(out.physicalStatus);
row.theta_deg = c.x(8)*180/pi; row.collective_deg = c.u(1)*180/pi;
row.cyclicLong_deg = c.u(3)*180/pi; row.elevator_deg = c.u(6)*180/pi;
row.udot = xdot(1); row.wdot = xdot(3); row.qdot = xdot(5);
row.meanRotorThrust_N = 0.5*(L.thrust+R.thrust);
row.meanRotorTorque_Nm = 0.5*(L.torque+R.torque);
row.totalRotorPower_kW = (L.torque+R.torque)*P.rotor.Omega/1000;
row.meanInducedVelocity_mps = 0.5*(L.inducedVelocity+R.inducedVelocity);
row.meanHlong_N = 0.5*(L.Hlong+R.Hlong);
row.meanHmag_N = 0.5*(hypot(L.Hlong,L.Hlat)+hypot(R.Hlong,R.Hlat));
row.meanBeta0_deg = 0.5*(L.beta0+R.beta0)*180/pi;
row.meanBeta1c_deg = 0.5*(L.beta1c+R.beta1c)*180/pi;
row.meanBeta1s_deg = 0.5*(L.beta1s+R.beta1s)*180/pi;
row.wingFx_N = comp.wing.F(1); row.wingFz_N = comp.wing.F(3); row.wingMy_Nm = comp.wing.M(2);
row.fuselageFx_N = comp.fuselage.F(1); row.fuselageFz_N = comp.fuselage.F(3); row.fuselageMy_Nm = comp.fuselage.M(2);
row.horizontalTailFx_N = comp.horizontalTail.F(1); row.horizontalTailFz_N = comp.horizontalTail.F(3); row.horizontalTailMy_Nm = comp.horizontalTail.M(2);
row.verticalTailFx_N = comp.verticalTail.F(1); row.verticalTailFz_N = comp.verticalTail.F(3); row.verticalTailMy_Nm = comp.verticalTail.M(2);
end

function d = make_delta(m0,m1)
d = empty_delta_row(); d.caseName = m0.caseName;
d.comparable = logical(m0.centerReproduced && m1.centerReproduced);
fields = {'theta_deg','collective_deg','cyclicLong_deg','elevator_deg', ...
    'meanRotorThrust_N','meanRotorTorque_Nm','totalRotorPower_kW','meanInducedVelocity_mps', ...
    'meanHlong_N','meanHmag_N','wingFx_N','wingFz_N','wingMy_Nm','fuselageFx_N','fuselageFz_N', ...
    'fuselageMy_Nm','horizontalTailFx_N','horizontalTailFz_N','horizontalTailMy_Nm', ...
    'verticalTailFx_N','verticalTailFz_N','verticalTailMy_Nm'};
for k = 1:numel(fields)
    nm = fields{k}; v0 = m0.(nm); v1 = m1.(nm);
    d.(['delta_' nm]) = v1-v0;
    d.(['pct_' nm]) = percent_delta(v0,v1);
end
end

function p = percent_delta(v0,v1)
if abs(v0) < 1e-12, p = NaN; else, p = 100*(v1-v0)/abs(v0); end
end

function r = empty_point_row()
r = struct('caseName',"",'modelIdentity',"",'mode',"",'centerSource',"", ...
    'sourceWorkflowRun',NaN,'sourceArtifactId',NaN,'sourceHeadSha',"", ...
    'sourceResidualNorm',NaN,'reevaluatedResidualNorm',NaN,'residualDelta',NaN, ...
    'sourceCredible',false,'centerReproduced',false,'physicalConverged',false, ...
    'physicalBranchSupported',false,'physicalStatus',"",'theta_deg',NaN,'collective_deg',NaN, ...
    'cyclicLong_deg',NaN,'elevator_deg',NaN,'udot',NaN,'wdot',NaN,'qdot',NaN, ...
    'meanRotorThrust_N',NaN,'meanRotorTorque_Nm',NaN,'totalRotorPower_kW',NaN, ...
    'meanInducedVelocity_mps',NaN,'meanHlong_N',NaN,'meanHmag_N',NaN, ...
    'meanBeta0_deg',NaN,'meanBeta1c_deg',NaN,'meanBeta1s_deg',NaN, ...
    'wingFx_N',NaN,'wingFz_N',NaN,'wingMy_Nm',NaN,'fuselageFx_N',NaN,'fuselageFz_N',NaN, ...
    'fuselageMy_Nm',NaN,'horizontalTailFx_N',NaN,'horizontalTailFz_N',NaN,'horizontalTailMy_Nm',NaN, ...
    'verticalTailFx_N',NaN,'verticalTailFz_N',NaN,'verticalTailMy_Nm',NaN);
end

function d = empty_delta_row()
d = struct('caseName',"",'comparable',false);
fields = {'theta_deg','collective_deg','cyclicLong_deg','elevator_deg', ...
    'meanRotorThrust_N','meanRotorTorque_Nm','totalRotorPower_kW','meanInducedVelocity_mps', ...
    'meanHlong_N','meanHmag_N','wingFx_N','wingFz_N','wingMy_Nm','fuselageFx_N','fuselageFz_N', ...
    'fuselageMy_Nm','horizontalTailFx_N','horizontalTailFz_N','horizontalTailMy_Nm', ...
    'verticalTailFx_N','verticalTailFz_N','verticalTailMy_Nm'};
for k=1:numel(fields)
    d.(['delta_' fields{k}]) = NaN;
    d.(['pct_' fields{k}]) = NaN;
end
end
