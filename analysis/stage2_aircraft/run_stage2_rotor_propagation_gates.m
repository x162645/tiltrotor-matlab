function results = run_stage2_rotor_propagation_gates(outputDir)
%RUN_STAGE2_ROTOR_PROPAGATION_GATES Required gates before aircraft analysis.

rootDir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(rootDir,'results','stage2_rotor_propagation_gates');
end
if ~exist(outputDir,'dir'), mkdir(outputDir); end

P = stage2_matched_rotor_parameters();
d2r = pi/180;
x75 = P.stage2RotorMapping.theta75LinearFraction;

%% Gate 1: analysis M0 backend must be identical to production rotor call.
theta75Gate = 10*d2r;
ctrl = struct('collective',theta75Gate-P.rotor.twistTip*x75, ...
    'cyclicLong',0);
x = zeros(9,1); cgShift=zeros(3,1); betaM=0; side=-1;
[Fdirect,Mdirect,odirect] = rotor_model_bemt(x,ctrl,betaM,side,cgShift,P);
[Fbackend,Mbackend,obackend] = stage2_rotor_backend( ...
    'M0_MATCHED_PRODUCTION',x,ctrl,betaM,side,cgShift,P);
m0Diff = max([abs(Fdirect-Fbackend);abs(Mdirect-Mbackend); ...
    abs(odirect.thrust-obackend.thrust);abs(odirect.torque-obackend.torque); ...
    abs(odirect.inducedVelocity-obackend.inducedVelocity)]);
m0Gate = table(theta75Gate/d2r,m0Diff,odirect.physicalConverged, ...
    obackend.physicalConverged, ...
    'VariableNames',{'theta75Deg','maxAbsoluteIdentityDifference', ...
    'productionPhysicalConverged','backendPhysicalConverged'});
writetable(m0Gate,fullfile(outputDir,'STAGE2_M0_BACKEND_IDENTITY.csv'));
if ~(m0Diff <= 1e-12 && odirect.physicalConverged && obackend.physicalConverged)
    error('run_stage2_rotor_propagation_gates:M0IdentityFail', ...
        'M0 analysis backend did not reproduce production path.');
end

%% Gate 2: exact hover anchor must reproduce frozen Stage-3 Corrigan n=1.
refDir = fullfile(outputDir,'frozen_stage3_reference');
stage3 = run_m1_stage3_corrigan_stall_delay(refDir);
ref = stage3.points(strcmp(stage3.points.mode,'CORRIGAN_GENERIC_N1'),:);
if height(ref) ~= 6
    error('run_stage2_rotor_propagation_gates:ReferenceMissing', ...
        'Expected six frozen Corrigan n=1 reference points.');
end
rows = table();
for k=1:height(ref)
    Pk=P;
    Vtip=ref.Vtip_fps(k)*0.3048;
    Pk.rotor.Omega=Vtip/Pk.rotor.R;
    theta75=ref.collective75_deg(k)*d2r;
    ctrl=struct('collective',theta75-Pk.rotor.twistTip*x75,'cyclicLong',0);
    [~,~,o]=stage2_rotor_backend('M1_EVIDENCE_V1_PROPAGATION', ...
        zeros(9,1),ctrl,0,-1,zeros(3,1),Pk);
    A=pi*Pk.rotor.R^2;
    CT=o.thrust/(Pk.env.rho*A*Vtip^2);
    CP=o.torque*Pk.rotor.Omega/(Pk.env.rho*A*Vtip^3);
    if CT>0 && CP>0, FM=CT^(3/2)/(sqrt(2)*CP); else, FM=NaN; end
    one=table(ref.collective75_deg(k),ref.CT_model(k),CT,abs(CT-ref.CT_model(k)), ...
        ref.CP_model(k),CP,abs(CP-ref.CP_model(k)), ...
        ref.FM_model(k),FM,abs(FM-ref.FM_model(k)),o.physicalConverged, ...
        {o.propagationBranch}, ...
        'VariableNames',{'theta75Deg','CT_frozen','CT_forwardAnchor','CT_absDiff', ...
        'CP_frozen','CP_forwardAnchor','CP_absDiff','FM_frozen','FM_forwardAnchor', ...
        'FM_absDiff','physicalConverged','branch'});
    rows=[rows;one]; %#ok<AGROW>
end
writetable(rows,fullfile(outputDir,'STAGE2_M1_HOVER_IDENTITY.csv'));
maxHoverDiff=max([rows.CT_absDiff;rows.CP_absDiff;rows.FM_absDiff]);
if ~(all(rows.physicalConverged) && isfinite(maxHoverDiff) && maxHoverDiff<=1e-10)
    error('run_stage2_rotor_propagation_gates:M1HoverIdentityFail', ...
        'M1 forward propagation hover anchor drifted from frozen M1: %.12g.',maxHoverDiff);
end

%% Near-hover extension diagnostic. This is reported, not used as validation.
Pk=P;
refPoint=rows(rows.theta75Deg==10,:);
Pk.rotor.Omega=(ref.Vtip_fps(ref.collective75_deg==10)*0.3048)/Pk.rotor.R;
theta75=10*d2r;
ctrl=struct('collective',theta75-Pk.rotor.twistTip*x75,'cyclicLong',0);
[~,~,hover]=stage2_rotor_backend('M1_EVIDENCE_V1_PROPAGATION', ...
    zeros(9,1),ctrl,0,-1,zeros(3,1),Pk);
Vdiag=[0.01;0.10;1.00];
continuity=table();
for k=1:numel(Vdiag)
    xd=zeros(9,1); xd(1)=Vdiag(k);
    try
        [~,~,od]=stage2_rotor_backend('M1_EVIDENCE_V1_PROPAGATION', ...
            xd,ctrl,0,-1,zeros(3,1),Pk);
        one=table(Vdiag(k),od.physicalConverged,od.thrust,od.torque, ...
            100*(od.thrust-hover.thrust)/hover.thrust, ...
            100*(od.torque-hover.torque)/hover.torque,{od.propagationBranch}, ...
            'VariableNames',{'V_mps','physicalConverged','thrust_N','torque_Nm', ...
            'thrustDeltaFromHover_pct','torqueDeltaFromHover_pct','branch'});
    catch ME
        one=table(Vdiag(k),false,NaN,NaN,NaN,NaN,{ME.identifier}, ...
            'VariableNames',{'V_mps','physicalConverged','thrust_N','torque_Nm', ...
            'thrustDeltaFromHover_pct','torqueDeltaFromHover_pct','branch'});
    end
    continuity=[continuity;one]; %#ok<AGROW>
end
writetable(continuity,fullfile(outputDir,'STAGE2_M1_NEAR_HOVER_DIAGNOSTIC.csv'));

summary=table(m0Diff,maxHoverDiff,all(rows.physicalConverged), ...
    sum(continuity.physicalConverged), ...
    {'PASS_IDENTITY_GATES_FORWARD_EXTENSION_REMAINS_PROPAGATION_ONLY'}, ...
    'VariableNames',{'M0BackendMaxAbsDifference','M1HoverMaxAbsDifference', ...
    'M1HoverAllPhysical','nearHoverSupportedCount','decision'});
writetable(summary,fullfile(outputDir,'STAGE2_ROTOR_GATE_SUMMARY.csv'));

results=struct('m0Gate',m0Gate,'hoverIdentity',rows,'nearHover',continuity, ...
    'summary',summary,'matchedParameters',P.stage2RotorMapping);
save(fullfile(outputDir,'STAGE2_ROTOR_PROPAGATION_GATES.mat'),'results');
end
