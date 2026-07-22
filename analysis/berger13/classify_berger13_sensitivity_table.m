function tableOut = classify_berger13_sensitivity_table(tableOut)
%CLASSIFY_BERGER13_SENSITIVITY_TABLE Apply common-metric classifications.

parameters = unique(tableOut.parameter,'stable');
for k = 1:numel(parameters)
    parameter = parameters{k};
    mask = strcmp(tableOut.parameter,parameter);
    if ismember(parameter,{'omegaN','zeta','lateralCyclicScale', ...
            'nacelleInertia'})
        tableOut.classificationMetric(mask) = ...
            tableOut.validPeakAttitudeRad(mask);
        tableOut.classificationMetricDefinition(mask) = repmat( ...
            {'valid-prefix peak attitude deviation [rad]'},sum(mask),1);
    elseif strcmp(parameter,'wakeArea')
        tableOut.classificationMetric(mask) = ...
            tableOut.momentDerivativeNormNmPerRad(mask);
        tableOut.classificationMetricDefinition(mask) = repmat( ...
            {'norm(dM/dBetaDiff) [N*m/rad]'},sum(mask),1);
    else
        tableOut.classificationMetric(mask) = ...
            tableOut.validMaxBetaDiffRad(mask);
        tableOut.classificationMetricDefinition(mask) = repmat( ...
            {'valid-prefix maxBetaDiff [rad]'},sum(mask),1);
    end
    values = tableOut.classificationMetric(mask);
    if ismember(parameter,{'rateScale','accelLim','torqueLim'}) && ...
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
end
