function tableOut = run_berger13_sensitivity_corrected(trimReport,P13)
%RUN_BERGER13_SENSITIVITY_CORRECTED Dimensionally consistent sensitivities.

parameters = {'omegaN','zeta','lateralCyclicScale','leftOmegaN', ...
    'leftZeta','rateScale','accelLim','torqueLim','movingMassLeft', ...
    'nacelleInertia','leftDelay','wakeArea'};
factors = [0.5,1,1.5];
rows = cell(numel(parameters)*numel(factors),25);
row = 0;
for p = 1:numel(parameters)
    for k = 1:numel(factors)
        row = row+1;
        [Ptest,caseDef] = sensitivity_case( ...
            P13,parameters{p},factors(k));
        sim = simulate_berger13_case(trimReport,Ptest,caseDef);
        [modalMetrics,spectralDiagnostic] = modal_metrics( ...
            trimReport,Ptest,parameters{p});
        [forceNorm,momentNorm] = beta_diff_load_derivatives( ...
            trimReport,Ptest);
        targetLimitActive = target_limit_active(sim,parameters{p});
        metric = primary_metric(sim,parameters{p},momentNorm);
        rows(row,:) = {parameters{p},factors(k), ...
            modalMetrics.actuatorReal,modalMetrics.actuatorImag, ...
            modalMetrics.actuatorDamping,modalMetrics.actuatorFrequencyHz, ...
            modalMetrics.dutchReal,modalMetrics.dutchImag, ...
            modalMetrics.shortReal,modalMetrics.shortImag, ...
            modalMetrics.spiralReal,spectralDiagnostic, ...
            sim.validPrefixMetrics.maxBetaDiffRad, ...
            sim.validPrefixMetrics.maxAbsRollMomentNm, ...
            sim.validPrefixMetrics.maxAbsYawMomentNm, ...
            sim.validPrefixMetrics.maxAttitudeDeviationRad, ...
            sim.validPrefixMetrics.recoveryTimeSeconds, ...
            sim.firstEnvelopeViolationTime,forceNorm,momentNorm, ...
            targetLimitActive,metric,primary_metric_name(parameters{p}), ...
            'PENDING_CLASSIFICATION','PENDING_REASON'};
    end
end
tableOut = cell2table(rows,'VariableNames', ...
    {'parameter','factor','actuatorModeRealPerSecond', ...
    'actuatorModeImagRadPerSecond','actuatorModeDampingRatio', ...
    'actuatorModeFrequencyHz','dutchModeRealPerSecond', ...
    'dutchModeImagRadPerSecond','shortPeriodRealPerSecond', ...
    'shortPeriodImagRadPerSecond','spiralModeRealPerSecond', ...
    'spectralAbscissaDiagnosticPerSecond','validMaxBetaDiffRad', ...
    'validPeakRollMomentNm','validPeakYawMomentNm', ...
    'validPeakAttitudeRad','validRecoveryTimeSeconds', ...
    'firstEnvelopeViolationTime','forceDerivativeNormNPerRad', ...
    'momentDerivativeNormNmPerRad','targetLimitActivated', ...
    'classificationMetric','classificationMetricDefinition', ...
    'conclusionClass','classificationReason'});
for p = 1:numel(parameters)
    mask = strcmp(tableOut.parameter,parameters{p});
    values = tableOut.classificationMetric(mask);
    if ismember(parameters{p},{'rateScale','accelLim','torqueLim'}) && ...
            ~any(tableOut.targetLimitActivated(mask))
        classification = 'CANNOT_RELIABLY_DETERMINE';
        reason = 'target limit was not activated inside the analysis guard';
    elseif any(~isfinite(values))
        classification = 'CANNOT_RELIABLY_DETERMINE';
        reason = 'the common valid-prefix metric is not finite for all factors';
    else
        relativeRange = (max(values)-min(values))/ ...
            max(max(abs(values)),1e-12);
        if relativeRange < 0.05
            classification = 'TREND_ROBUST';
            reason = 'common valid-prefix metric changes by less than 5%';
        elseif relativeRange < 0.5
            classification = 'MAGNITUDE_SENSITIVE';
            reason = 'common valid-prefix metric changes by 5% to 50%';
        else
            classification = 'HIGHLY_ASSUMPTION_DEPENDENT';
            reason = 'common valid-prefix metric changes by at least 50%';
        end
    end
    tableOut.conclusionClass(mask) = repmat({classification},sum(mask),1);
    tableOut.classificationReason(mask) = repmat({reason},sum(mask),1);
end
tableOut = classify_berger13_sensitivity_table(tableOut);
end

function [Ptest,def] = sensitivity_case(P13,parameter,factor)
d2r = pi/180;
Ptest = P13;
def = struct('name',['sensitivity_' parameter], ...
    'duration',3,'dt',0.025,'inputType','betaSym', ...
    'amplitude',1*d2r,'startTime',0.5);
switch parameter
    case 'omegaN'
        Ptest.commandActuator.left.omegaN = ...
            factor*P13.commandActuator.left.omegaN;
        Ptest.commandActuator.right.omegaN = ...
            factor*P13.commandActuator.right.omegaN;
    case 'zeta'
        Ptest.commandActuator.left.zeta = ...
            factor*P13.commandActuator.left.zeta;
        Ptest.commandActuator.right.zeta = ...
            factor*P13.commandActuator.right.zeta;
    case 'lateralCyclicScale'
        Ptest.interface.lateralCyclicScale = factor;
        def.inputType = 'lateralCyclic';
        def.amplitude = 0.15*d2r;
    case 'leftOmegaN'
        Ptest.commandActuator.left.omegaN = ...
            factor*P13.commandActuator.left.omegaN;
    case 'leftZeta'
        Ptest.commandActuator.left.zeta = ...
            factor*P13.commandActuator.left.zeta;
    case 'rateScale'
        Ptest.commandActuator.left.rateScale = factor;
    case 'accelLim'
        Ptest.commandActuator.left.accelLim = ...
            factor*P13.commandActuator.left.accelLim;
    case 'torqueLim'
        Ptest.nacelle.torqueLim = factor*P13.nacelle.torqueLim;
    case 'movingMassLeft'
        Ptest.movingComponents.left.mass = ...
            factor*P13.movingComponents.left.mass;
        def.inputType = 'betaDiff';
        def.amplitude = 0.5*d2r;
    case 'nacelleInertia'
        Ptest.nacelle.I = factor*P13.nacelle.I;
    case 'leftDelay'
        Ptest.commandActuator.left.commandDelay = 0.2*factor;
    case 'wakeArea'
        Ptest.base.wing.SslipMaxHalf = ...
            factor*P13.base.wing.SslipMaxHalf;
    otherwise
        error('run_berger13_sensitivity_corrected:UnknownParameter', ...
            'Unknown parameter %s.',parameter);
end
end

function [metrics,spectral] = modal_metrics(trimReport,P13,parameter)
fields = {'actuatorReal','actuatorImag','actuatorDamping', ...
    'actuatorFrequencyHz','dutchReal','dutchImag','shortReal', ...
    'shortImag','spiralReal'};
for k = 1:numel(fields), metrics.(fields{k}) = NaN; end
spectral = NaN;
if ~ismember(parameter,{'omegaN','zeta','leftOmegaN','leftZeta'})
    return;
end
[A,B] = linearize_13x10_command_numeric( ...
    trimReport.x13,trimReport.u10Command,P13,1);
transform = berger13_symdiff_transform(A,B,'ANGLE_COMMAND');
modal = analyze_berger13_modes( ...
    transform.A,transform.B,transform.stateNames,transform.inputNames);
spectral = max(real(modal.eigenvalues(~modal.table.headingIntegrator)));
index = selected_mode(modal,'nacelle actuator');
if ~isnan(index)
    metrics.actuatorReal = real(modal.eigenvalues(index));
    metrics.actuatorImag = imag(modal.eigenvalues(index));
    metrics.actuatorDamping = modal.table.dampingRatio(index);
    metrics.actuatorFrequencyHz = modal.table.frequencyHz(index);
end
index = selected_mode(modal,'dutch-roll-like');
if ~isnan(index)
    metrics.dutchReal = real(modal.eigenvalues(index));
    metrics.dutchImag = imag(modal.eigenvalues(index));
end
index = selected_mode(modal,'short-period-like');
if ~isnan(index)
    metrics.shortReal = real(modal.eigenvalues(index));
    metrics.shortImag = imag(modal.eigenvalues(index));
end
index = selected_mode(modal,'spiral-like');
if ~isnan(index), metrics.spiralReal = real(modal.eigenvalues(index)); end
end

function index = selected_mode(modal,pattern)
indices = find(contains(modal.table.modeName,pattern));
if isempty(indices)
    index = NaN;
    return;
end
positiveImag = indices(imag(modal.eigenvalues(indices)) >= -1e-10);
if ~isempty(positiveImag), indices = positiveImag; end
[~,local] = max(modal.table.rigidBodyParticipation(indices));
index = indices(local);
end

function active = target_limit_active(sim,parameter)
switch parameter
    case 'rateScale'
        active = any(sim.limitDetails.leftRateClamped);
    case 'accelLim'
        active = any(sim.limitDetails.leftAccelerationClamped);
    case 'torqueLim'
        active = any(sim.limitDetails.leftTorqueClamped | ...
            sim.limitDetails.rightTorqueClamped);
    otherwise
        active = true;
end
end

function value = primary_metric(sim,parameter,momentNorm)
if strcmp(parameter,'wakeArea')
    value = momentNorm;
elseif ismember(parameter,{'omegaN','zeta','lateralCyclicScale', ...
        'nacelleInertia'})
    value = sim.validPrefixMetrics.maxAttitudeDeviationRad;
else
    value = sim.validPrefixMetrics.maxBetaDiffRad;
end
end

function name = primary_metric_name(parameter)
if strcmp(parameter,'wakeArea')
    name = 'norm(dM/dBetaDiff) [N*m/rad]';
elseif ismember(parameter,{'omegaN','zeta','lateralCyclicScale', ...
        'nacelleInertia'})
    name = 'valid-prefix peak attitude deviation [rad]';
else
    name = 'valid-prefix maxBetaDiff [rad]';
end
end

function [forceNorm,momentNorm] = beta_diff_load_derivatives(trimReport,P13)
h = 1e-4;
xp = trimReport.x13; xm = trimReport.x13;
xp(10:11) = xp(10:11)+[-h;+h];
xm(10:11) = xm(10:11)+[+h;-h];
uTorque = [trimReport.u10Command(1:8);0;0];
[Fp,Mp] = total_forces_moments_13x10(xp,uTorque,P13);
[Fm,Mm] = total_forces_moments_13x10(xm,uTorque,P13);
forceNorm = norm((Fp-Fm)/(2*h));
momentNorm = norm((Mp-Mm)/(2*h));
end
