function results = run_xv15_spanwise_c81_diagnostic(outputDir)
%RUN_XV15_SPANWISE_C81_DIAGNOSTIC Execute the C81 scalarization diagnostic.
%
% Compare under identical PR67 XV-15 hover geometry/OARF conditions:
%   1) generic default section parameters;
%   2) NASA C81 reduced to one scalar low-order section model (PR68);
%   3) NASA C81 restored as four spanwise regions with local-Mach lookup.
%
% OARF CT/CP/FM are external comparison only and are never used to identify
% section parameters.

rootDir = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(rootDir,'results','xv15_section_aero_validation');
end
if ~exist(outputDir,'dir')
    mkdir(outputDir);
end

Pbase = params_nominal();
d2r = pi/180;
R = 3.81;
rootCut = 0.0875;

collective75_deg = [0;2;4;6;7;8;9;10;11];
Vtip_fps = [769.0;768.7;768.4;768.4;768.4;768.4;768.0;768.0;767.7];
CT_exp = [0.004063;0.005581;0.007391;0.009208;0.010104; ...
          0.011063;0.012035;0.013089;0.013929];
CP_exp = [0.000315;0.000426;0.000588;0.000796;0.000913; ...
          0.001044;0.001188;0.001358;0.001523];
FM_exp = [0.5814;0.6921;0.7641;0.7849;0.7866; ...
          0.7881;0.7858;0.7797;0.7632];

%% Frozen PR67 geometry/input reduction.
xGeom = linspace(rootCut,1,4001).';
chord_in = 14*ones(size(xGeom));
inboard = xGeom <= 0.25;
chord_in(inboard) = -18.4615*xGeom(inboard)+18.6154;
chord_m = chord_in*0.0254;
chordEq_m = trapz(xGeom,chord_m)/(1-rootCut);

thetaSource_deg = nasa_metal_twist_deg(xGeom);
theta75Source_deg = nasa_metal_twist_deg(0.75);
xNorm = (xGeom-rootCut)/(1-rootCut);
x75 = (0.75-rootCut)/(1-rootCut);
shapeCoordinate = xNorm-x75;
shapeTarget = thetaSource_deg-theta75Source_deg;
twistTipEq_deg = trapz(xGeom,shapeCoordinate.*shapeTarget) / ...
    trapz(xGeom,shapeCoordinate.^2);

scalarC81 = build_xv15_c81_low_order_section_aero();

Ptemplate = Pbase;
Ptemplate.rotor.R = R;
Ptemplate.rotor.Nb = 3;
Ptemplate.rotor.rootCut = rootCut;
Ptemplate.rotor.chord = chordEq_m;
Ptemplate.rotor.twistTip = twistTipEq_deg*d2r;
Ptemplate.rotor.Ib = Ptemplate.rotor.bladeMass*R^2/3;
Ptemplate.rotor.Sblade = Ptemplate.rotor.bladeMass*R/2;

variant = {'GENERIC_LOW_ORDER';'SCALAR_C81_LOW_ORDER'; ...
    'SPANWISE_C81_LOCAL_MACH'};

rows = table();
consistency = table();
for v = 1:numel(variant)
    for k = 1:numel(collective75_deg)
        P = Ptemplate;
        Vtip_mps = Vtip_fps(k)*0.3048;
        P.rotor.Omega = Vtip_mps/R;
        modelCollective_deg = collective75_deg(k)-twistTipEq_deg*x75;

        out = xv15_hover_bemt_section_diagnostic( ...
            P,modelCollective_deg*d2r,variant{v},scalarC81);

        A = pi*R^2;
        CT_model = NaN; CP_model = NaN; FM_model = NaN;
        if isfinite(out.thrust) && isfinite(out.torque)
            CT_model = out.thrust/(P.env.rho*A*Vtip_mps^2);
            CP_model = out.torque*P.rotor.Omega/(P.env.rho*A*Vtip_mps^3);
            if CT_model > 0 && CP_model > 0
                FM_model = CT_model^(3/2)/(sqrt(2)*CP_model);
            end
        end

        local = table(variant(v),collective75_deg(k),Vtip_fps(k), ...
            P.rotor.Omega*60/(2*pi),modelCollective_deg, ...
            CT_exp(k),CT_model,CP_exp(k),CP_model,FM_exp(k),FM_model, ...
            out.physicalConverged,{out.physicalStatus},out.inducedVelocity, ...
            out.inducedClosureResidualRelative,out.alphaMin_deg,out.alphaMax_deg, ...
            out.machMin,out.machMax,out.c81AlphaClampCount,out.c81MachClampCount, ...
            'VariableNames',{'variant','collective75_deg','Vtip_fps','rpm', ...
            'modelCollective_deg','CT_exp','CT_model','CP_exp','CP_model', ...
            'FM_exp','FM_model','physicalConverged','physicalStatus', ...
            'inducedVelocity_mps','closureResidualRelative','alphaMin_deg', ...
            'alphaMax_deg','machMin','machMax','c81AlphaClampCount', ...
            'c81MachClampCount'});
        rows = [rows;local]; %#ok<AGROW>

        % Before interpreting the table-lookup result, prove that the mirror
        % reproduces the production paths for the two modes production can
        % already express exactly.
        if v <= 2
            Pprod = P;
            if v == 1
                if isfield(Pprod.rotor,'alpha0L')
                    Pprod.rotor = rmfield(Pprod.rotor,'alpha0L');
                end
            else
                Pprod.rotor.alpha0L = scalarC81.alpha0L_rad;
                Pprod.rotor.liftSlope = scalarC81.liftSlope;
                Pprod.rotor.CLmax = scalarC81.CLmax;
                Pprod.rotor.CD0 = scalarC81.CD0;
                Pprod.rotor.kCD = scalarC81.kCD;
                Pprod.rotor.enableCompressibilityCorrection = false;
            end
            ctrl = struct('collective',modelCollective_deg*d2r,'cyclicLong',0);
            prodReturned = true;
            prodCT = NaN; prodCP = NaN; prodPhysical = false;
            try
                [~,~,prodOut] = rotor_model_bemt_section_aero( ...
                    zeros(9,1),ctrl,0,-1,zeros(3,1),Pprod);
                prodCT = prodOut.thrust/(P.env.rho*A*Vtip_mps^2);
                prodCP = prodOut.torque*P.rotor.Omega/(P.env.rho*A*Vtip_mps^3);
                prodPhysical = prodOut.physicalConverged;
            catch
                prodReturned = false;
            end

            relCT = abs(CT_model-prodCT)/max([abs(CT_model),abs(prodCT),1e-12]);
            relCP = abs(CP_model-prodCP)/max([abs(CP_model),abs(prodCP),1e-12]);
            mirrorMatches = prodReturned && ...
                (isnan(CT_model) == isnan(prodCT)) && ...
                (isnan(CP_model) == isnan(prodCP));
            if isfinite(relCT) && isfinite(relCP)
                mirrorMatches = mirrorMatches && relCT < 1e-9 && relCP < 1e-9;
            end

            cRow = table(variant(v),collective75_deg(k),prodReturned, ...
                out.physicalConverged,prodPhysical,CT_model,prodCT,relCT, ...
                CP_model,prodCP,relCP,mirrorMatches, ...
                'VariableNames',{'variant','collective75_deg','prodReturned', ...
                'mirrorPhysical','productionPhysical','mirrorCT','productionCT', ...
                'relativeCTDifference','mirrorCP','productionCP', ...
                'relativeCPDifference','mirrorMatches'});
            consistency = [consistency;cRow]; %#ok<AGROW>
        end
    end
end

writetable(rows,fullfile(outputDir,'XV15_SPANWISE_C81_MATLAB_VALIDATION.csv'));
writetable(consistency,fullfile(outputDir,'XV15_SPANWISE_C81_MIRROR_CONSISTENCY.csv'));

%% Fair comparison on the common physically converged range used before.
commonCollectives = [6;7;8;9;10;11];
metrics = table();
for v = 1:numel(variant)
    mask = strcmp(rows.variant,variant{v}) & ...
        ismember(rows.collective75_deg,commonCollectives) & ...
        rows.physicalConverged;
    local = rows(mask,:);
    if height(local) == numel(commonCollectives)
        CT_MAPE_pct = 100*mean(abs(local.CT_model-local.CT_exp)./local.CT_exp);
        CP_MAPE_pct = 100*mean(abs(local.CP_model-local.CP_exp)./local.CP_exp);
        FM_MAPE_pct = 100*mean(abs(local.FM_model-local.FM_exp)./local.FM_exp);
    else
        CT_MAPE_pct = NaN; CP_MAPE_pct = NaN; FM_MAPE_pct = NaN;
    end
    mRow = table(variant(v),height(local),CT_MAPE_pct,CP_MAPE_pct,FM_MAPE_pct, ...
        'VariableNames',{'variant','commonPointCount','CT_MAPE_pct', ...
        'CP_MAPE_pct','FM_MAPE_pct'});
    metrics = [metrics;mRow]; %#ok<AGROW>
end
writetable(metrics,fullfile(outputDir,'XV15_SPANWISE_C81_MATLAB_METRICS.csv'));

results = struct();
results.validationTable = rows;
results.metricTable = metrics;
results.mirrorConsistencyTable = consistency;
results.scalarC81 = scalarC81;
results.chordEq_m = chordEq_m;
results.twistTipEq_deg = twistTipEq_deg;
results.claimBoundary = ['SPANWISE_C81_SECTION_DIAGNOSTIC_' ...
    'SAME_HOVER_BEMT_NO_OARF_PARAMETER_FIT'];
save(fullfile(outputDir,'XV15_SPANWISE_C81_DIAGNOSTIC_RESULTS.mat'),'results');
end

function theta_deg = nasa_metal_twist_deg(x)
theta_deg = 289.98*x.^5-892.87*x.^4+987.06*x.^3 ...
    -438.31*x.^2+15.695*x+32.057;
end
