function R = evaluate_generic_trim_robustness(initialDatabase)
%EVALUATE_GENERIC_TRIM_ROBUSTNESS Post-freeze bounded C2 perturbation study.
% Six deterministic perturbations are applied only after the final values
% were frozen.  They are validation probes and never feed parameter choice.

[Pnom,manifest]=params_generic_trim_optimized();
names={'nominal';'low_corner';'high_corner';'mixed_a';'mixed_b'; ...
    'effective_low';'effective_high'};
delta=[0 0 0 0; -0.02 -0.02 -0.5 -0.05; ...
    0.02 0.02 0.5 0.05; 0.02 -0.02 -0.5 0.05; ...
    -0.02 0.02 0.5 -0.05; 0 0 0 -0.05; 0 0 0 0.05];
ids={'B45_V025';'B75_V040';'B75_V060'};
G=generic_trim_design_grid();

rows=repmat(empty_row(),numel(names)*numel(ids),1); n=0;
for s=1:numel(names)
    P=Pnom;
    P.base.wing.xAC=P.base.wing.xAC+delta(s,1);
    P.base.rotor.pivotZ=P.base.rotor.pivotZ+delta(s,2);
    P.base.htail.incidence=P.base.htail.incidence+delta(s,3)*pi/180;
    P.base.htail.CLelevator=P.base.htail.CLelevator+delta(s,4);
    for j=1:numel(ids)
        n=n+1; rows(n).scenario=names{s}; rows(n).pointId=ids{j};
        rows(n).wingXAC=P.base.wing.xAC;
        rows(n).rotorPivotZ=P.base.rotor.pivotZ;
        rows(n).tailIncidenceDeg=P.base.htail.incidence*180/pi;
        rows(n).tailCLelevator=P.base.htail.CLelevator;
        k=find(strcmp(G.pointId,ids{j}),1);
        opts=struct('mode',G.mode{k},'runMultipleSeeds',false);
        if nargin>=1 && ~isempty(initialDatabase) && ...
                ~isempty(initialDatabase.points(k).trim)
            opts.initialValues=initialDatabase.points(k).trim.trimVariableVector;
        end
        started=tic;
        try
            [~,~,tr]=trim_berger13_symmetric(G.condition{k},P,opts);
            rows(n).status=tr.status; rows(n).credible=tr.credible;
            rows(n).thetaDeg=tr.x13(8)*180/pi;
            rows(n).elevatorDeg=tr.u10Torque(7)*180/pi;
            rows(n).residualNorm=tr.dynamicResidualNorm;
            rows(n).conditionNumber=tr.conditionNumber;
            rows(n).minimumMarginFraction=tr.minimumUnknownMarginFraction;
            rows(n).finiteReal=tr.finiteReal;
        catch ME
            rows(n).status='ERROR'; rows(n).failureReason=ME.message;
        end
        rows(n).elapsedSeconds=toc(started);
    end
end
R=struct2table(rows);
R.Properties.Description=['POST_FREEZE_ROBUSTNESS_SET; deterministic ' ...
    'bounded perturbations; excluded from objective and parameter selection'];
R.Properties.UserData.manifest=manifest;
end

function r=empty_row()
r=struct('scenario','','pointId','','wingXAC',NaN,'rotorPivotZ',NaN, ...
    'tailIncidenceDeg',NaN,'tailCLelevator',NaN,'status','FAILED', ...
    'credible',false,'thetaDeg',NaN,'elevatorDeg',NaN, ...
    'residualNorm',Inf,'conditionNumber',Inf, ...
    'minimumMarginFraction',-Inf,'finiteReal',false, ...
    'elapsedSeconds',NaN,'failureReason','');
end
