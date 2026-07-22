function T = pitch_moment_decomposition(database)
%PITCH_MOMENT_DECOMPOSITION Decompose component My about actual total CG.

rows = repmat(empty_row(),0,1);
for k = 1:numel(database.points)
    point = database.points(k);
    if isempty(point.trim), continue; end
    info = point.trim.point.eomOut.components13;
    for j = 1:numel(info.components)
        comp = info.components{j};
        if strcmp(comp.name,'wing') && isfield(comp.data,'left')
            rows(end+1) = make_row(database.variantName,point, ...
                'wingLeft',comp.data.left.F,comp.data.left.M, ...
                comp.data.left,point.trim); %#ok<AGROW>
            rows(end+1) = make_row(database.variantName,point, ...
                'wingRight',comp.data.right.F,comp.data.right.M, ...
                comp.data.right,point.trim); %#ok<AGROW>
        end
        rows(end+1) = make_row(database.variantName,point,comp.name, ...
            comp.F,comp.M,comp.data,point.trim); %#ok<AGROW>
    end
    total = make_row(database.variantName,point,'TOTAL', ...
        info.F,info.M,struct(),point.trim);
    total.armMomentMyNm = sum([rows(strcmp({rows.pointId},point.id) & ...
        ~strcmp({rows.component},'wingLeft') & ...
        ~strcmp({rows.component},'wingRight')).armMomentMyNm]);
    total.intrinsicMomentMyNm = total.MyNm-total.armMomentMyNm;
    rows(end+1) = total; %#ok<AGROW>
    gravity = make_row(database.variantName,point, ...
        'gravity_or_CG_effect',[0;0;0],[0;0;0],struct(),point.trim);
    gravity.note = ['Gravity is applied through the actual CG in the rigid-' ...
        'body equations, so its explicit moment about that CG is zero.'];
    rows(end+1) = gravity; %#ok<AGROW>
end
T = struct2table(rows);
end

function row = make_row(variant,point,name,F,M,data,trim)
row = empty_row();
row.variant = variant;
row.pointId = point.id;
row.betaMDeg = point.condition.betaM*180/pi;
row.speedMps = point.condition.V;
row.trimStatus = point.status;
row.component = name;
row.FxN = F(1); row.FyN = F(2); row.FzN = F(3);
row.MxNm = M(1); row.MyNm = M(2); row.MzNm = M(3);
[r,arm,intrinsic,V,qbar,alpha] = diagnostics(data,F,M);
row.rXFromActualCGm = r(1); row.rYFromActualCGm = r(2);
row.rZFromActualCGm = r(3);
row.armMomentMyNm = arm(2);
row.intrinsicMomentMyNm = intrinsic(2);
row.localSpeedMps = V;
row.localDynamicPressurePa = qbar;
row.localAlphaDeg = alpha*180/pi;
row.elevatorDeg = trim.u10Torque(7)*180/pi;
row.controlAtLimit = any(trim.activeLimits);
row.finiteReal = isreal([F(:);M(:)]) && all(isfinite([F(:);M(:)]));
end

function [r,arm,intrinsic,V,qbar,alpha] = diagnostics(data,F,M)
r = [NaN;NaN;NaN]; arm = [NaN;NaN;NaN];
V = NaN; qbar = NaN; alpha = NaN;
if isfield(data,'rHub'), r = data.rHub(:); end
if isfield(data,'rAC'), r = data.rAC(:); end
if isfield(data,'Marm'), arm = data.Marm(:); end
if any(isnan(arm)) && isfield(data,'regions')
    arm = zeros(3,1);
    for k = 1:numel(data.regions)
        region = data.regions{k};
        if isfield(region,'Marm'), arm = arm+region.Marm(:); end
    end
end
if any(isnan(arm)) && all(isfinite(r)), arm = cross(r,F(:)); end
intrinsic = M(:)-arm;
if isfield(data,'V'), V = data.V; end
if isfield(data,'Vlocal'), V = norm(data.Vlocal); end
if isfield(data,'Vhub'), V = norm(data.Vhub); end
if isfield(data,'qbar'), qbar = data.qbar; end
if isfield(data,'alpha'), alpha = data.alpha; end
if isfield(data,'alphaLocal'), alpha = data.alphaLocal; end
end

function row = empty_row()
row = struct('variant','','pointId','','betaMDeg',NaN,'speedMps',NaN, ...
    'trimStatus','','component','','FxN',NaN,'FyN',NaN,'FzN',NaN, ...
    'MxNm',NaN,'MyNm',NaN,'MzNm',NaN,'rXFromActualCGm',NaN, ...
    'rYFromActualCGm',NaN,'rZFromActualCGm',NaN,'armMomentMyNm',NaN, ...
    'intrinsicMomentMyNm',NaN,'localSpeedMps',NaN, ...
    'localDynamicPressurePa',NaN,'localAlphaDeg',NaN, ...
    'elevatorDeg',NaN,'controlAtLimit',false,'finiteReal',false, ...
    'note','');
end
