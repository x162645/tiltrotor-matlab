function results = run_aircraft_hover_m0_m1_model_form_transfer(outputDir)
%RUN_AIRCRAFT_HOVER_M0_M1_MODEL_FORM_TRANSFER Generic-aircraft hover propagation.
%
% Question: with the SAME generic params_nominal aircraft and no XV-15
% parameter export, how does the predeclared Corrigan n=1 model-form change
% collective/power/inflow required to support aircraft weight in hover?
%
% This is a model-form transfer sensitivity, NOT XV-15 aircraft validation.
% It is intentionally restricted to betaM=0, V=0, zero cyclic.

rootDir=fileparts(fileparts(mfilename('fullpath')));
if nargin<1 || isempty(outputDir)
    outputDir=fullfile(rootDir,'results','aircraft_hover_m0_m1_model_form_transfer');
end
if ~exist(outputDir,'dir'), mkdir(outputDir); end

% Must pass both identity gates before propagation is interpreted.
audit=audit_m1_model_form_instance_separation(fullfile(outputDir,'identity_audit'));

P=params_nominal();
targetPerRotor=P.mass.m*P.env.g/2;

m0=solve_collective(@eval_m0,targetPerRotor);
m1=solve_collective(@eval_m1,targetPerRotor);

summary=table( ...
    {'M0_PRODUCTION';'M1_GENERIC_CORRIGAN_N1'}, ...
    [m0.collectiveDeg;m1.collectiveDeg], ...
    [m0.out.thrust;m1.out.thrust], ...
    [m0.out.torque;m1.out.torque], ...
    [m0.powerPerRotor_W;m1.powerPerRotor_W], ...
    [2*m0.powerPerRotor_W;2*m1.powerPerRotor_W], ...
    [m0.inducedVelocity_mps;m1.inducedVelocity_mps], ...
    [m0.FM;m1.FM], ...
    [m0.out.physicalConverged;m1.out.physicalConverged], ...
    'VariableNames',{'model','rootCollective_deg','perRotorThrust_N', ...
    'perRotorTorque_Nm','perRotorPower_W','totalRotorPower_W', ...
    'inducedVelocity_mps','FM','physicalConverged'});
writetable(summary,fullfile(outputDir,'AIRCRAFT_HOVER_M0_M1_TRANSFER_SUMMARY.csv'));

delta=table( ...
    m1.collectiveDeg-m0.collectiveDeg, ...
    100*(m1.collectiveDeg-m0.collectiveDeg)/m0.collectiveDeg, ...
    2*(m1.powerPerRotor_W-m0.powerPerRotor_W), ...
    100*(m1.powerPerRotor_W-m0.powerPerRotor_W)/m0.powerPerRotor_W, ...
    m1.inducedVelocity_mps-m0.inducedVelocity_mps, ...
    m1.FM-m0.FM, ...
    'VariableNames',{'deltaCollective_deg','deltaCollective_pct', ...
    'deltaTotalRotorPower_W','deltaTotalRotorPower_pct', ...
    'deltaInducedVelocity_mps','deltaFM'});
writetable(delta,fullfile(outputDir,'AIRCRAFT_HOVER_M0_M1_TRANSFER_DELTA.csv'));

% Common-control diagnostic: quantify direct load change at M0 trim control.
outM1AtM0=eval_m1(m0.collectiveDeg*pi/180);
commonControl=table(m0.collectiveDeg,m0.out.thrust,outM1AtM0.thrust, ...
    outM1AtM0.thrust-m0.out.thrust, ...
    100*(outM1AtM0.thrust-m0.out.thrust)/m0.out.thrust, ...
    m0.powerPerRotor_W,outM1AtM0.power, ...
    100*(outM1AtM0.power-m0.powerPerRotor_W)/m0.powerPerRotor_W, ...
    'VariableNames',{'rootCollective_deg','M0_thrust_N','M1_thrust_N', ...
    'deltaThrust_N','deltaThrust_pct','M0_power_W','M1_power_W','deltaPower_pct'});
writetable(commonControl,fullfile(outputDir,'AIRCRAFT_HOVER_COMMON_CONTROL_DIAGNOSTIC.csv'));

metadata=table( ...
    {'role';'aircraft_parameter_set';'xv15_parameters_exported'; ...
     'operating_domain';'cyclic';'nacelle_angle';'target'; ...
     'validation_claim';'next_gate'}, ...
    {'WHOLE_AIRCRAFT_HOVER_MODEL_FORM_PROPAGATION_SENSITIVITY'; ...
     'PARAMS_NOMINAL_GENERIC_CONCEPT';'NO';'STRICT_HOVER_ONLY';'ZERO'; ...
     'BETA_M_ZERO';'TWO_ROTORS_SUPPORT_MG'; ...
     'NOT_XV15_AIRCRAFT_VALIDATION'; ...
     'DO_NOT_EXTEND_TO_CONVERSION_UNTIL_FORWARD_FLIGHT_M1_MODEL_FORM_IS_INDEPENDENTLY_DEFINED'}, ...
    'VariableNames',{'name','value'});
writetable(metadata,fullfile(outputDir,'AIRCRAFT_HOVER_M0_M1_TRANSFER_METADATA.csv'));

results.summary=summary;
results.delta=delta;
results.commonControl=commonControl;
results.identityAudit=audit;
results.targetPerRotor_N=targetPerRotor;
results.metadata=metadata;
save(fullfile(outputDir,'AIRCRAFT_HOVER_M0_M1_TRANSFER_RESULTS.mat'),'results');

    function out=eval_m0(theta)
        x=zeros(9,1);
        ctrl=struct('collective',theta,'cyclicLong',0);
        [~,~,raw]=rotor_model_bemt(x,ctrl,0,-1,zeros(3,1),P);
        out=raw;
        out.power=raw.torque*P.rotor.Omega;
        out.FM=NaN;
        A=pi*P.rotor.R^2; tip=P.rotor.Omega*P.rotor.R;
        CT=raw.thrust/(P.env.rho*A*tip^2);
        CP=raw.torque*P.rotor.Omega/(P.env.rho*A*tip^3);
        if CT>0 && CP>0, out.FM=CT^(3/2)/(sqrt(2)*CP); end
    end

    function out=eval_m1(theta)
        out=rotor_m1_hover_model_form(P,theta, ...
            struct('instanceType','GENERIC_NOMINAL_INSTANCE','corriganMode','N1'));
    end
end

function sol=solve_collective(fun,targetThrust)
% Deterministic supported-branch scan + bisection; no data fitting.
gridDeg=(4:0.5:24).';
vals=NaN(size(gridDeg)); supported=false(size(gridDeg)); outs=cell(size(gridDeg));
for k=1:numel(gridDeg)
    try
        o=fun(gridDeg(k)*pi/180);
        ok=isfield(o,'physicalConverged') && o.physicalConverged && ...
            isfinite(o.thrust) && o.thrust>0;
        if ok
            vals(k)=o.thrust-targetThrust;
            supported(k)=true;
            outs{k}=o;
        end
    catch
        % Unsupported trial is retained implicitly by supported=false.
    end
end
idx=[];
for k=1:numel(gridDeg)-1
    if supported(k) && supported(k+1) && vals(k)<=0 && vals(k+1)>=0
        idx=k; break;
    end
end
if isempty(idx)
    error('run_aircraft_hover_m0_m1_model_form_transfer:NoBracket', ...
        'Could not bracket target thrust on a supported 4-24 deg branch.');
end
lo=gridDeg(idx)*pi/180; hi=gridDeg(idx+1)*pi/180;
olo=outs{idx}; ohi=outs{idx+1}; %#ok<NASGU>
for iter=1:60
    mid=0.5*(lo+hi);
    omid=fun(mid);
    if ~omid.physicalConverged
        error('run_aircraft_hover_m0_m1_model_form_transfer:InteriorUnsupported', ...
            'Bisection entered an unsupported physical branch.');
    end
    fmid=omid.thrust-targetThrust;
    if abs(fmid)/targetThrust<1e-8 || abs(hi-lo)<1e-10
        break;
    end
    if fmid>=0, hi=mid; else, lo=mid; end
end
sol.collectiveDeg=mid*180/pi;
sol.out=omid;
sol.powerPerRotor_W=omid.power;
sol.inducedVelocity_mps=omid.inducedVelocity;
sol.FM=omid.FM;
sol.relativeThrustResidual=abs(omid.thrust-targetThrust)/targetThrust;
if sol.relativeThrustResidual>1e-7
    error('run_aircraft_hover_m0_m1_model_form_transfer:ThrustResidual', ...
        'Hover weight-support solve residual %.3e.',sol.relativeThrustResidual);
end
end
