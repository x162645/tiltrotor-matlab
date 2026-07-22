function [J,terms] = generic_trim_objective(summary,P13)
%GENERIC_TRIM_OBJECTIVE Auditable scalar score for the frozen 9-point set.
% Failures are retained and heavily penalized.  Margin targets of 5/10/15%
% are ASSUMED design requirements, not source-aircraft specifications.

if nargin < 2 || isempty(P13), P13=params_berger13(); end
required = {'status','dynamicResidualNorm','conditionNumber', ...
    'collectiveDeg','cyclicLongDeg','elevatorDeg'};
if ~all(ismember(required,summary.Properties.VariableNames))
    error('generic_trim_objective:InvalidSummary','Summary fields are missing.');
end

credible = strcmp(summary.status,'CREDIBLE');
residual = summary.dynamicResidualNorm;
residual(~isfinite(residual)) = 1e3;
condition = summary.conditionNumber;
condition(~isfinite(condition)) = 1e6;

controlMargin = minimum_control_margin(summary,P13.base.control);
targets = [0.05 0.10 0.15];
marginPenalty = zeros(size(controlMargin));
for k=1:numel(targets)
    marginPenalty = marginPenalty + max(0,targets(k)-controlMargin).^2;
end

terms.failure = 1e4*sum(~credible);
terms.residual = sum(log10(1+residual/1e-6));
terms.conditioning = 0.01*sum(log10(max(condition,1)));
terms.controlMargin = 100*sum(marginPenalty);
terms.external = 0; % Frozen qualitative holdout is never in the objective.
J = terms.failure+terms.residual+terms.conditioning+ ...
    terms.controlMargin+terms.external;
terms.total = J;
terms.assumedMarginTargets = targets;
end

function margin = minimum_control_margin(S,C)
limits = [C.collectiveLim;C.cyclicLim;C.elevatorLim]*180/pi;
values = [S.collectiveDeg,S.cyclicLongDeg,S.elevatorDeg];
margin = Inf(height(S),1);
for j=1:3
    span=limits(j,2)-limits(j,1);
    margin=min(margin,min((values(:,j)-limits(j,1))/span, ...
        (limits(j,2)-values(:,j))/span));
end
margin(~isfinite(margin))=-Inf;
end
