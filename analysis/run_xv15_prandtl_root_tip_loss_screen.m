function results = run_xv15_prandtl_root_tip_loss_screen(outputDir)
%RUN_XV15_PRANDTL_ROOT_TIP_LOSS_SCREEN
% 对 XV-15 原始金属桨悬停工况做 Prandtl 有限叶片根尖损失量级筛查。
%
% 本诊断固定真实径向几何、完整四区 C81/局部 Mach、第一谐波挥舞
% 和 Eq. (12) 方位入流，只在独立环带动量闭合中比较：
%   1) 不含根尖损失；
%   2) 只含 Prandtl 尖端损失；
%   3) 同时含 Prandtl 根部和尖端损失。
%
% 损失因子只修正环带动量关系：
%   dT = 2*rho*dA*F*vi^2
% 不直接缩放叶素升阻力。OARF Run 15 数据只用于求解后的外部比较，
% 不参与损失因子、气动参数或数值参数的定义。
%
% 方程来源：
% - Prandtl/Glauert 尖端因子采用有限叶片 BEM 常用形式；
% - 根部因子采用同一涡片逻辑在 rootCut 处的对应形式；
% - NASA 悬停 BEMT 推导同样将组合根尖因子 F 乘在局部动量推力项上。

rootDir = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(rootDir,'results','xv15_section_aero_validation');
end
if ~exist(outputDir,'dir')
    mkdir(outputDir);
end

Pbase = params_nominal();
R = 3.81;
rootCut = 0.0875;

collective75_deg = [6;7;8;9;10;11];
Vtip_fps = [768.4;768.4;768.4;768.0;768.0;767.7];
CT_exp = [0.009208;0.010104;0.011063;0.012035;0.013089;0.013929];
CP_exp = [0.000796;0.000913;0.001044;0.001188;0.001358;0.001523];
FM_exp = [0.7849;0.7866;0.7881;0.7858;0.7797;0.7632];

Ptemplate = Pbase;
Ptemplate.rotor.R = R;
Ptemplate.rotor.Nb = 3;
Ptemplate.rotor.rootCut = rootCut;
Ptemplate.rotor.nRadial = 48;
Ptemplate.rotor.Ib = Ptemplate.rotor.bladeMass*R^2/3;
Ptemplate.rotor.Sblade = Ptemplate.rotor.bladeMass*R/2;
if ~isfield(Ptemplate.env,'aSound')
    Ptemplate.env.aSound = 340.0;
end

rows = table();
for k = 1:numel(collective75_deg)
    P = Ptemplate;
    Vtip_mps = Vtip_fps(k)*0.3048;
    P.rotor.Omega = Vtip_mps/R;

    globalOut = solve_hover(P,collective75_deg(k),'GLOBAL','NONE',[]);
    noLoss = solve_hover(P,collective75_deg(k),'ANNULAR','NONE', ...
        globalOut.inducedVelocity);
    tipOnly = solve_hover(P,collective75_deg(k),'ANNULAR','TIP_ONLY', ...
        globalOut.inducedVelocity);
    tipRoot = solve_hover(P,collective75_deg(k),'ANNULAR','TIP_ROOT', ...
        globalOut.inducedVelocity);

    A = pi*R^2;
    [CTn,CPn,FMn] = nondim(noLoss,P,A,Vtip_mps);
    [CTt,CPt,FMt] = nondim(tipOnly,P,A,Vtip_mps);
    [CTr,CPr,FMr] = nondim(tipRoot,P,A,Vtip_mps);

    one = table(collective75_deg(k),Vtip_fps(k),CT_exp(k),CP_exp(k),FM_exp(k), ...
        CTn,CPn,FMn,CTt,CPt,FMt,CTr,CPr,FMr, ...
        tipOnly.minTipFactor,tipOnly.areaMeanTipFactor, ...
        tipRoot.minRootFactor,tipRoot.areaMeanRootFactor, ...
        tipRoot.minCombinedFactor,tipRoot.areaMeanCombinedFactor, ...
        noLoss.minRingThrust_N,tipOnly.minRingThrust_N, ...
        tipRoot.minRingThrust_N, ...
        noLoss.physicalConverged,tipOnly.physicalConverged, ...
        tipRoot.physicalConverged,noLoss.maxLocalClosureResidualRelative, ...
        tipOnly.maxLocalClosureResidualRelative, ...
        tipRoot.maxLocalClosureResidualRelative, ...
        noLoss.solverConverged,tipOnly.solverConverged, ...
        tipRoot.solverConverged,tipOnly.finalInducedError, ...
        tipRoot.finalInducedError, ...
        tipRoot.alphaClampCount,tipRoot.machClampCount, ...
        'VariableNames',{'collective75_deg','Vtip_fps','CT_exp','CP_exp','FM_exp', ...
        'CT_annularNoLoss','CP_annularNoLoss','FM_annularNoLoss', ...
        'CT_prandtlTip','CP_prandtlTip','FM_prandtlTip', ...
        'CT_prandtlTipRoot','CP_prandtlTipRoot','FM_prandtlTipRoot', ...
        'minTipFactor','areaMeanTipFactor','minRootFactor','areaMeanRootFactor', ...
        'minCombinedFactor','areaMeanCombinedFactor', ...
        'noLossMinRingThrust_N','tipMinRingThrust_N', ...
        'tipRootMinRingThrust_N', ...
        'noLossSupported','tipSupported','tipRootSupported', ...
        'noLossMaxClosureResidualRelative', ...
        'tipMaxClosureResidualRelative','tipRootMaxClosureResidualRelative', ...
        'noLossSolverConverged','tipSolverConverged', ...
        'tipRootSolverConverged','tipFinalInducedError', ...
        'tipRootFinalInducedError', ...
        'tipRootAlphaClampCount','tipRootMachClampCount'});
    rows = [rows;one]; %#ok<AGROW>
end

writetable(rows,fullfile(outputDir, ...
    'XV15_PRANDTL_ROOT_TIP_LOSS_MATLAB_SCREEN.csv'));

common = rows.noLossSupported & rows.tipSupported & rows.tipRootSupported;
windows = {true(height(rows),1),rows.collective75_deg >= 9};
windowNames = ["6-11";"9-11"];
metrics = table(windowNames,'VariableNames',{'window'});
metrics.nCommon = [nnz(common & windows{1});nnz(common & windows{2})];
metricNames = {'CT','CP','FM'};
modelNames = {'annularNoLoss','prandtlTip','prandtlTipRoot'};
for iq = 1:numel(metricNames)
    quantity = metricNames{iq};
    experiment = rows.([quantity '_exp']);
    for im = 1:numel(modelNames)
        field = [quantity '_' modelNames{im}];
        metricField = [quantity '_MAPE_' modelNames{im} '_pct'];
        values = NaN(2,1);
        for iw = 1:2
            mask = common & windows{iw};
            values(iw) = mape(rows.(field),experiment,mask);
        end
        metrics.(metricField) = values;
    end
end
writetable(metrics,fullfile(outputDir, ...
    'XV15_PRANDTL_ROOT_TIP_LOSS_MATLAB_METRICS.csv'));

% 根尖损失因子在叶根和叶尖附近变化最快，因此只在 10 deg 代表点
% 做一次 12/24/48/96 径向离散检查，不扩展到全工况扫描。
gridN = [12;24;48;96];
gridRows = table();
for j = 1:numel(gridN)
    P = Ptemplate;
    P.rotor.nRadial = gridN(j);
    Vtip_mps = 768.0*0.3048;
    P.rotor.Omega = Vtip_mps/R;
    globalOut = solve_hover(P,10,'GLOBAL','NONE',[]);
    noLoss = solve_hover(P,10,'ANNULAR','NONE',globalOut.inducedVelocity);
    tipOnly = solve_hover(P,10,'ANNULAR','TIP_ONLY',globalOut.inducedVelocity);
    tipRoot = solve_hover(P,10,'ANNULAR','TIP_ROOT',globalOut.inducedVelocity);
    A = pi*R^2;
    [CTn,CPn,~] = nondim(noLoss,P,A,Vtip_mps);
    [CTt,CPt,~] = nondim(tipOnly,P,A,Vtip_mps);
    [CTr,CPr,~] = nondim(tipRoot,P,A,Vtip_mps);
    one = table(gridN(j),CTn,CPn,CTt,CPt,CTr,CPr, ...
        tipOnly.minTipFactor,tipRoot.minRootFactor, ...
        tipRoot.minCombinedFactor,tipRoot.areaMeanCombinedFactor, ...
        noLoss.physicalConverged,tipOnly.physicalConverged, ...
        tipRoot.physicalConverged,tipRoot.maxLocalClosureResidualRelative, ...
        'VariableNames',{'nRadial','CT_annularNoLoss','CP_annularNoLoss', ...
        'CT_prandtlTip','CP_prandtlTip','CT_prandtlTipRoot', ...
        'CP_prandtlTipRoot','minTipFactor','minRootFactor', ...
        'minCombinedFactor','areaMeanCombinedFactor','noLossSupported', ...
        'tipSupported','tipRootSupported','tipRootMaxClosureResidualRelative'});
    gridRows = [gridRows;one]; %#ok<AGROW>
end
writetable(gridRows,fullfile(outputDir, ...
    'XV15_PRANDTL_ROOT_TIP_LOSS_GRID_MATLAB_SCREEN.csv'));

results = struct();
results.table = rows;
results.metrics = metrics;
results.grid = gridRows;
results.claimBoundary = ['PRANDTL_ROOT_TIP_LOSS_MAGNITUDE_SCREEN_' ...
    'ANNULAR_MOMENTUM_ONLY_NO_OARF_FIT_NO_PRODUCTION_MODEL_CHANGE'];
save(fullfile(outputDir, ...
    'XV15_PRANDTL_ROOT_TIP_LOSS_SCREEN_RESULTS.mat'),'results');
end

function out = solve_hover(P,theta75_deg,closureMode,lossMode,viInitial)
closureMode = upper(char(closureMode));
lossMode = upper(char(lossMode));
R = P.rotor.R;
Omega = P.rotor.Omega;
tipSpeed = Omega*R;
rho = P.env.rho;
A = pi*R^2;
r0 = P.rotor.rootCut*R;
rEdges = linspace(r0,R,P.rotor.nRadial+1);
rMid = 0.5*(rEdges(1:end-1)+rEdges(2:end));
dr = diff(rEdges);
dA = pi*(rEdges(2:end).^2-rEdges(1:end-1).^2);
psi = ((0:P.rotor.nAzimuth-1)*(2*pi/P.rotor.nAzimuth)).';

x = rMid/R;
chord_in = 14*ones(size(x));
inboard = x <= 0.25;
chord_in(inboard) = -18.4615*x(inboard)+18.6154;
chord_m = chord_in*0.0254;
thetaSource_deg = nasa_metal_twist_deg(x);
theta75Source_deg = nasa_metal_twist_deg(0.75);
thetaBlade = (theta75_deg+thetaSource_deg-theta75Source_deg)*pi/180;
UT = Omega*rMid;

if isempty(viInitial)
    vi0 = sqrt(max(P.mass.m*P.env.g/2,1)/(2*rho*A));
else
    vi0 = viInitial;
end
zFlap = P.rotor.flapInitial(:);
if numel(zFlap) ~= 3
    error('P.rotor.flapInitial must contain [beta0; beta1c; beta1s].');
end
err = Inf;

if strcmp(closureMode,'GLOBAL')
    if ~strcmp(lossMode,'NONE')
        error('Global closure is used only as the no-loss initializer.');
    end
    vi = vi0;
    converged = false;
    flapInfo = empty_flap_info();
    for iter = 1:P.rotor.inducedMaxIter
        [zFlap,flapInfo] = solve_flap(vi,zFlap);
        if ~flapInfo.converged
            break;
        end
        loads = blade_loads(vi,zFlap);
        lambda1 = -vi/max(tipSpeed,eps);
        CTiter = max(loads.T,0)/(0.5*rho*A*tipSpeed^2);
        viTarget = tipSpeed*CTiter/(4*max(abs(lambda1),1e-12));
        viNew = 0.5*(vi+viTarget);
        err = abs(viNew-vi)/max(1,abs(vi));
        vi = viNew;
        if err < P.rotor.inducedTol && ...
                flapInfo.residualNorm <= P.rotor.flapResidualTol
            converged = true;
            break;
        end
    end
    loads = blade_loads(vi,zFlap);
    lambda1 = -vi/max(tipSpeed,eps);
    momentumThrust = 2*rho*A*tipSpeed*vi*abs(lambda1);
    closureResidualRelative = abs(loads.T-momentumThrust)/ ...
        max([abs(loads.T),abs(momentumThrust),1]);
    physical = converged && flapInfo.converged && loads.T > 0 && ...
        closureResidualRelative <= 2.0e-4;
    loss = unit_loss_factors();
    maxLocalClosureResidualRelative = NaN;
else
    vi = vi0*ones(1,P.rotor.nRadial);
    converged = false;
    flapInfo = empty_flap_info();
    maxIter = max(200,10*P.rotor.inducedMaxIter);
    for iter = 1:maxIter
        [zFlap,flapInfo] = solve_flap(vi,zFlap);
        if ~flapInfo.converged
            break;
        end
        loads = blade_loads(vi,zFlap);
        loss = prandtl_loss_factors(vi,lossMode);
        viTarget = sqrt(max(loads.ringThrust_N,0)./ ...
            (2*rho*dA.*loss.combined));
        viNew = (1-P.rotor.inducedRelax)*vi+ ...
            P.rotor.inducedRelax*viTarget;
        err = max(abs(viNew-vi)./max(1,abs(vi)));
        vi = viNew;
        if err < 1.0e-6
            converged = true;
            break;
        end
    end
    loads = blade_loads(vi,zFlap);
    loss = prandtl_loss_factors(vi,lossMode);
    momentumRingThrust = 2*rho*dA.*loss.combined.*vi.^2;
    localResidual = loads.ringThrust_N-momentumRingThrust;
    localScale = max(max(abs(loads.ringThrust_N), ...
        abs(momentumRingThrust)),1);
    localResidualRelative = abs(localResidual)./localScale;
    maxLocalClosureResidualRelative = max(localResidualRelative);
    physical = converged && flapInfo.converged && ...
        all(loads.ringThrust_N > 0) && ...
        maxLocalClosureResidualRelative <= 2.0e-4;
end

out.thrust = loads.T;
out.torque = loads.Q;
out.inducedVelocity = vi;
out.zFlap = zFlap;
out.flap = flapInfo;
out.solverConverged = converged;
out.inducedIterations = iter;
out.finalInducedError = err;
out.physicalConverged = physical;
out.maxLocalClosureResidualRelative = maxLocalClosureResidualRelative;
out.alphaClampCount = loads.alphaClampCount;
out.machClampCount = loads.machClampCount;
out.minRingThrust_N = min(loads.ringThrust_N);
out.minTipFactor = min(loss.tip);
out.areaMeanTipFactor = sum(loss.tip.*dA)/sum(dA);
out.minRootFactor = min(loss.root);
out.areaMeanRootFactor = sum(loss.root.*dA)/sum(dA);
out.minCombinedFactor = min(loss.combined);
out.areaMeanCombinedFactor = sum(loss.combined.*dA)/sum(dA);
out.claimBoundary = ['ACTUAL_GEOMETRY_FULL_C81_' closureMode '_' lossMode ...
    '_PRANDTL_SCREEN_NO_OARF_PARAMETER_FIT'];

    function [z,info] = solve_flap(viNow,z0)
        z = z0(:);
        info = empty_flap_info();
        for kk = 1:P.rotor.flapMaxIter
            [res,scale] = flap_residual(z,viNow);
            rn = res/scale;
            if norm(rn) <= P.rotor.flapResidualTol
                info.converged = true;
                info.iterations = kk;
                info.residualNorm = norm(rn);
                return;
            end
            J = zeros(3,3);
            for jj = 1:3
                h = P.rotor.flapJacobianStep*max(1,abs(z(jj)));
                zp = z;
                zm = z;
                zp(jj) = zp(jj)+h;
                zm(jj) = zm(jj)-h;
                [rp,~] = flap_residual(zp,viNow);
                [rm,~] = flap_residual(zm,viNow);
                J(:,jj) = (rp-rm)/(2*h*scale);
            end
            if ~all(isfinite(J(:))) || rcond(J.'*J) < 1e-14
                return;
            end
            reg = P.rotor.flapNewtonRegularization;
            dz = -(J.'*J+reg*eye(3))\(J.'*rn);
            step = 1.0;
            accepted = false;
            for trial = 1:P.rotor.flapLineSearchMaxIter
                zc = z+step*dz;
                betaCheck = zc(1)+zc(2)*cos(psi)+zc(3)*sin(psi);
                if all(isfinite(zc)) && ...
                        max(abs(betaCheck)) < P.rotor.flapDivergenceAngle
                    [rc,sc] = flap_residual(zc,viNow);
                    if norm(rc/sc) < norm(rn)
                        z = zc;
                        accepted = true;
                        break;
                    end
                end
                step = step*P.rotor.flapNewtonDamping;
            end
            if ~accepted
                return;
            end
        end
        [res,scale] = flap_residual(z,viNow);
        info.iterations = P.rotor.flapMaxIter;
        info.residualNorm = norm(res/scale);
    end

    function [res,scale] = flap_residual(z,viNow)
        ll = blade_loads(viNow,z);
        gravityMoment = -P.rotor.Sblade*P.env.g*cos(ll.beta);
        inertialRestoring = P.rotor.Ib*ll.betaDDot+ ...
            P.rotor.Ib*Omega^2*ll.beta;
        byAz = inertialRestoring-ll.flapMomentByAzimuth-gravityMoment;
        res = [mean(byAz);2*mean(byAz.*cos(psi)); ...
            2*mean(byAz.*sin(psi))];
        scale = max([max(abs(ll.flapMomentByAzimuth)), ...
            max(abs(gravityMoment)),P.rotor.Ib*Omega^2*0.05,1]);
    end

    function ll = blade_loads(viNow,z)
        betaLocal = z(1)+z(2)*cos(psi)+z(3)*sin(psi);
        betaDotLocal = -Omega*(-z(2)*sin(psi)+z(3)*cos(psi));
        betaDDotLocal = -Omega^2*(z(2)*cos(psi)+z(3)*sin(psi));
        viField = viNow.*(1+cos(psi).*(rMid/R));
        UP = viField-betaDotLocal.*rMid;
        W = hypot(UT,UP);
        phi = atan2(UP,max(abs(UT),1e-8));
        alpha = thetaBlade-phi;
        Mach = W/P.env.aSound;
        [CL,CD,meta] = xv15_c81_section_lookup(alpha,Mach,rMid/R);

        q = 0.5*rho*W.^2;
        dL = q.*chord_m.*CL.*dr;
        dD = q.*chord_m.*CD.*dr;
        dT = dL.*cos(phi)-dD.*sin(phi);
        dH = dD.*cos(phi)+dL.*sin(phi);
        dQ = dH.*rMid;
        factor = P.rotor.Nb/P.rotor.nAzimuth;
        ll.ringThrust_N = factor*sum(dT,1);
        ll.ringTorque_Nm = factor*sum(dQ,1);
        ll.T = sum(ll.ringThrust_N);
        ll.Q = sum(ll.ringTorque_Nm);
        ll.flapMomentByAzimuth = sum(dT.*rMid,2);
        ll.beta = betaLocal;
        ll.betaDDot = betaDDotLocal;
        ll.alphaClampCount = meta.alphaClampCount;
        ll.machClampCount = meta.machClampCount;
    end

    function loss = prandtl_loss_factors(viNow,mode)
        % 轴对称平均入流角用于经典 Prandtl/Glauert 环带修正。
        phiMean = atan2(max(viNow,0),max(UT,1e-8));
        sinPhi = max(abs(sin(phiMean)),1e-12);
        fTip = 0.5*P.rotor.Nb*(R-rMid)./(rMid.*sinPhi);
        fRoot = 0.5*P.rotor.Nb*(rMid-r0)./(r0.*sinPhi);
        Ftip = (2/pi)*acos(clamp01(exp(-fTip)));
        Froot = (2/pi)*acos(clamp01(exp(-fRoot)));
        if strcmp(mode,'NONE')
            FtipApplied = ones(size(Ftip));
            FrootApplied = ones(size(Froot));
        elseif strcmp(mode,'TIP_ONLY')
            FtipApplied = Ftip;
            FrootApplied = ones(size(Froot));
        elseif strcmp(mode,'TIP_ROOT')
            FtipApplied = Ftip;
            FrootApplied = Froot;
        else
            error('Unknown Prandtl loss mode %s.',mode);
        end
        loss.tip = FtipApplied;
        loss.root = FrootApplied;
        loss.combined = FtipApplied.*FrootApplied;
    end

    function loss = unit_loss_factors()
        loss.tip = ones(1,P.rotor.nRadial);
        loss.root = ones(1,P.rotor.nRadial);
        loss.combined = ones(1,P.rotor.nRadial);
    end
end

function info = empty_flap_info()
info = struct('converged',false,'iterations',0,'residualNorm',Inf);
end

function value = clamp01(value)
value = min(max(value,0),1);
end

function [CT,CP,FM] = nondim(out,P,A,Vtip)
CT = out.thrust/(P.env.rho*A*Vtip^2);
CP = out.torque*P.rotor.Omega/(P.env.rho*A*Vtip^3);
if CT > 0 && CP > 0
    FM = CT^(3/2)/(sqrt(2)*CP);
else
    FM = NaN;
end
end

function value = mape(model,experiment,mask)
mask = mask & isfinite(model) & isfinite(experiment) & experiment ~= 0;
if ~any(mask)
    value = NaN;
else
    value = 100*mean(abs((model(mask)-experiment(mask))./experiment(mask)));
end
end

function theta_deg = nasa_metal_twist_deg(x)
theta_deg = 289.98*x.^5-892.87*x.^4+987.06*x.^3 ...
    -438.31*x.^2+15.695*x+32.057;
end
