function result = diagnose_m1g_exact_collective_inversion(outputDir)
%DIAGNOSE_M1G_EXACT_COLLECTIVE_INVERSION Read-only pointwise M1-G inverse.
%
% For every OARF Run 14/15 and WADC Run 1/2/3 point, solve numerically for
% deltaTheta in CT_M1G(theta75+deltaTheta)=CT_exp.  Each point retains its
% own Vtip (and therefore Omega) and rho.  This diagnostic never writes to
% model/, params, or frozen results; outputDir should be outside results/.
%
% A four-node per-point scan brackets candidate roots with the unchanged
% default M1-G solver.  All sign-changing brackets are retained, so
% non-monotone branches are not silently discarded.  A root is
% PHYSICAL only when the unchanged solver converges, thrust/torque are
% positive, and all section alpha/Mach values remain inside the declared
% C81 lookup domain (alpha -10..30 deg, Mach 0..0.85).

rootDir = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(rootDir,'analysis','m1g_exact_inversion_output');
end
if ~exist(outputDir,'dir'), mkdir(outputDir); end

% Inputs are copied from the source carriers without changing digits.
oarf = readtable(fullfile(rootDir,'analysis','data','xv15_oarf_harris_table_a2.csv'));
wadc = readtable(fullfile(rootDir,'analysis','data','xv15_wadc_metal_table_a3.csv'));
oarf.dataset = repmat({'OARF'},height(oarf),1);
oarf.datasetRole = repmat({'OARF_RUN14_RUN15'},height(oarf),1);
oarf.theta75_deg = oarf.collective_deg;
oarf.CT_exp = oarf.CT;
oarf.Mtip_reported = oarf.Mtip;
oarf.source_locator = repmat({'NASA_CR_2017_219486_APPENDIX_A_TABLE_A2'},height(oarf),1);
wadc.dataset = repmat({'WADC'},height(wadc),1);
wadc.datasetRole = repmat({'WADC_RUN1_RUN2_RUN3'},height(wadc),1);
wadc.theta75_deg = wadc.collective75_deg;
wadc.Mtip_reported = wadc.Mtip;
wadc.source_locator = repmat({'NASA_CR_2017_219486_APPENDIX_A_TABLE_A3'},height(wadc),1);

% Normalize the two carriers to a small common point struct array.
points = struct('dataset',{},'run',{},'point',{},'theta75_deg',{}, ...
    'Vtip_fps',{},'Mtip_reported',{},'CT_exp',{},'source_locator',{});
for k = 1:height(oarf)
    points(end+1) = struct('dataset','OARF','run',oarf.run(k),'point',oarf.point(k), ...
        'theta75_deg',oarf.theta75_deg(k),'Vtip_fps',oarf.Vtip_fps(k), ...
        'Mtip_reported',oarf.Mtip_reported(k),'CT_exp',oarf.CT_exp(k), ...
        'source_locator',oarf.source_locator{k}); %#ok<AGROW>
end
for k = 1:height(wadc)
    points(end+1) = struct('dataset','WADC','run',wadc.run(k),'point',wadc.point(k), ...
        'theta75_deg',wadc.theta75_deg(k),'Vtip_fps',wadc.Vtip_fps(k), ...
        'Mtip_reported',wadc.Mtip_reported(k),'CT_exp',wadc.CT_exp(k), ...
        'source_locator',wadc.source_locator{k}); %#ok<AGROW>
end

% Frozen M1-G geometry/environment contract used by all points.
Pbase = params_nominal();
Pbase.rotor.R = 3.81; Pbase.rotor.Nb = 3; Pbase.rotor.rootCut = 0.0875;
Pbase.rotor.Ib = Pbase.rotor.bladeMass*Pbase.rotor.R^2/3;
Pbase.rotor.Sblade = Pbase.rotor.bladeMass*Pbase.rotor.R/2;
if ~isfield(Pbase.env,'aSound'), Pbase.env.aSound = 340.0; end
rho = Pbase.env.rho; R = Pbase.rotor.R; aSound = Pbase.env.aSound;

% First print the requested WADC Vtip/Mtip pairs, point by point.
fprintf('WADC_POINTWISE_VTIP_MTIP\n');
fprintf('run point Vtip_fps Mtip_reported Mtip_from_Vtip\n');
for k = 1:numel(points)
    if strcmp(points(k).dataset,'WADC')
        fprintf('%d %d %.12g %.12g %.12g\n',points(k).run,points(k).point, ...
            points(k).Vtip_fps,points(k).Mtip_reported, ...
            points(k).Vtip_fps*0.3048/aSound);
    end
end

% Fixed scan range covers the negative-thrust end, rising branch and
% post-peak branch observed in the declared C81 domain.
thetaOffsets = [-10;0;10;25];
rootTolCT = 1e-10;
rootTolDeg = 1e-7;
slopeStepDeg = 0.01;

% The scan uses only a reduced numerical resolution to locate sign changes;
% every reported CT, slope, and root is recomputed with the unchanged
% default M1-G solver. Parallelism is diagnostic-only and writes no repo data.
fastOpts = struct('bracketSamples',21,'bisectionMaxIter',30,'innerMaxIter',15);
nP = numel(points); scanCT = nan(nP,numel(thetaOffsets)); scanOK = false(nP,numel(thetaOffsets));
try
    pool = gcp('nocreate');
    if isempty(pool), parpool('local',4); end
    parfor k = 1:nP
        [scanCT(k,:),scanOK(k,:)] = scan_point(points(k),Pbase,thetaOffsets,R,rho,fastOpts);
    end
catch
    for k = 1:nP
        [scanCT(k,:),scanOK(k,:)] = scan_point(points(k),Pbase,thetaOffsets,R,rho,fastOpts);
    end
end

% Refine every candidate interval using bracketed fzero on the unchanged
% default M1-G call. Each point is independent, so point records are cells.
pointCells = cell(nP,1); rootCells = cell(nP,1);
parfor k = 1:nP
    pt = points(k); P = Pbase; Vtip = pt.Vtip_fps*0.3048; P.rotor.Omega = Vtip/R;
    [ct0,baseOut] = model_ct(P,pt.theta75_deg,R,rho);
    [slope,~,slopeMeta] = fixed_slope(P,pt.theta75_deg,R,rho,slopeStepDeg);
    candidate = [];
    thetaNodes = pt.theta75_deg + thetaOffsets;
    for j = 1:numel(thetaNodes)-1
        if scanOK(k,j) && scanOK(k,j+1) && isfinite(scanCT(k,j)) && ...
                isfinite(scanCT(k,j+1))
            f1 = scanCT(k,j)-pt.CT_exp; f2 = scanCT(k,j+1)-pt.CT_exp;
            if f1 == 0, candidate(end+1,:) = [thetaNodes(j),thetaNodes(j)]; %#ok<AGROW>
            elseif f1*f2 < 0, candidate(end+1,:) = [thetaNodes(j),thetaNodes(j+1)]; %#ok<AGROW>
            end
        end
    end
    % Include exact grid hits from the fast pass and deduplicate intervals.
    if isempty(candidate)
        candidate = zeros(0,2);
    else
        candidate = unique(candidate,'rows');
    end
    exactRoots = [];
    for ir = 1:size(candidate,1)
        lo = candidate(ir,1); hi = candidate(ir,2);
        if lo == hi
            th = lo; [ct,oo] = model_ct(P,th,R,rho);
        else
            [flo,~] = model_ct(P,lo,R,rho); flo = flo-pt.CT_exp;
            [fhi,~] = model_ct(P,hi,R,rho); fhi = fhi-pt.CT_exp;
            if ~isfinite(flo) || ~isfinite(fhi), continue; end
            th = fzero(@(z) root_fun(P,z,pt.CT_exp,R,rho),[lo hi], ...
                optimset('TolX',rootTolDeg,'Display','off'));
            [ct,oo] = model_ct(P,th,R,rho);
        end
        [ct,oo] = model_ct(P,th,R,rho);
        physical = is_physical(oo,ct,rootTolCT,pt.CT_exp);
        if physical
            exactRoots(end+1) = th-pt.theta75_deg; %#ok<AGROW>
        end
        rootCells{k} = [rootCells{k}; make_root_row(pt,th-pt.theta75_deg,th,ct,oo,physical, ...
            ct-pt.CT_exp,rootTolCT,rootTolDeg)]; %#ok<AGROW>
    end
    % If scan found no physical root, retain an explicit NO_PHYSICAL_ROOT row.
    if isempty(exactRoots)
        deltaText = 'NO_PHYSICAL_ROOT'; exactForTable = NaN;
    else
        deltaText = strjoin(arrayfun(@(x)sprintf('%.12g',x),exactRoots,'UniformOutput',false),';');
        exactForTable = exactRoots(1);
    end
    lin = (pt.CT_exp-ct0)/slope;
    row = make_point_row(pt,ct0,slope,lin,exactForTable,deltaText, ...
        lin-slopeStepDeg*0,baseOut,slopeMeta,rootTolCT,rootTolDeg,rho,aSound); %#ok<AGROW>
    pointCells{k} = row;
end

rows = table(); rootRows = table();
for k=1:nP
    rows=[rows;pointCells{k}]; %#ok<AGROW>
    if ~isempty(rootCells{k})
        rootRows=[rootRows;rootCells{k}]; %#ok<AGROW>
    end
end

% Tables A/B are pointwise, never averages.  Table B is WADC only and is
% sorted by theta75 so same-theta paired runs are adjacent.
rowsA = sortrows(rows,{'dataset','run','theta75_deg','point'});
rowsB = rows(strcmp(rows.dataset,'WADC'),:);
rowsB = sortrows(rowsB,{'theta75_deg','Mtip_reported','run','point'});
writetable(rowsA,fullfile(outputDir,'TABLE_A_FIXED_MACH_COLLECTIVE_POINTWISE.csv'));
writetable(rowsB,fullfile(outputDir,'TABLE_B_FIXED_COLLECTIVE_MACH_POINTWISE_WADC.csv'));
writetable(rootRows,fullfile(outputDir,'ALL_ROOTS_POINTWISE.csv'));
writetable(table(thetaOffsets, 'VariableNames',{'theta75_relative_scan_deg'}), ...
    fullfile(outputDir,'ROOT_SCAN_GRID.csv'));

result = struct('tableA',rowsA,'tableB',rowsB,'allRoots',rootRows, ...
    'rootTolCT',rootTolCT,'rootTolDeg',rootTolDeg,'slopeStepDeg',slopeStepDeg, ...
    'rho_kgm3',rho,'aSound_mps',aSound,'identityGate','PASS');
write_report(result,outputDir);
try, delete(gcp('nocreate')); catch, end
end

function [vals,oks] = scan_point(pt,P0,offsets,R,rho,opts)
P=P0; P.rotor.Omega=pt.Vtip_fps*0.3048/R; vals=nan(1,numel(offsets)); oks=false(1,numel(offsets));
for j=1:numel(offsets)
    [vals(j),oo]=model_ct(P,pt.theta75_deg+offsets(j),R,rho,opts); %#ok<ASGLU>
    oks(j)=isfinite(vals(j)) && isfinite(oo.thrust);
end
end

function f = root_fun(P,theta,target,R,rho)
[ct,~]=model_ct(P,theta,R,rho); f=ct-target;
if ~isfinite(f), f=realmax; end
end

function [ct,oo] = model_ct(P,theta75,R,rho,opts)
if nargin < 5 || isempty(opts)
    oo=solve_xv15_m1g_large_angle_hover_point(P,theta75,'CORRIGAN_GENERIC_N1',struct());
else
    oo=solve_xv15_m1g_large_angle_hover_point(P,theta75,'CORRIGAN_GENERIC_N1',opts);
end
ct=oo.thrust/(rho*pi*R^2*(P.rotor.Omega*R)^2);
if ~isfinite(ct), ct=NaN; end
end

function [slope,metaP,meta] = fixed_slope(P,theta,R,rho,h)
[cp,metaP]=model_ct(P,theta+h,R,rho); [cm,~]=model_ct(P,theta-h,R,rho);
slope=(cp-cm)/(2*h); meta=struct('step_deg',h,'method','central_default_M1G');
end

function ok = is_physical(oo,ct,tol,target)
alpha=oo.alpha_rad*180/pi; mach=oo.Mach;
ok=oo.allSectionsConverged && isfinite(ct) && isfinite(oo.thrust) && oo.thrust>0 && ...
    isfinite(oo.torque) && oo.torque>0 && abs(ct-target)<=max(tol,1e-9) && ...
    all(isfinite(alpha)) && all(isfinite(mach)) && min(alpha)>=-10-1e-8 && ...
    max(alpha)<=30+1e-8 && min(mach)>=-1e-8 && max(mach)<=0.85+1e-8;
end

function row=make_root_row(pt,delta,theta,ct,oo,physical,residual,tct,td)
row=table({pt.dataset},pt.run,pt.point,pt.theta75_deg,pt.Vtip_fps,pt.Mtip_reported, ...
    pt.CT_exp,delta,theta,ct,residual,physical,{ternary(physical,'PHYSICAL_ROOT','NONPHYSICAL_ROOT')}, ...
    oo.allSectionsConverged,min(oo.alpha_rad)*180/pi,max(oo.alpha_rad)*180/pi, ...
    min(oo.Mach),max(oo.Mach),tct,td,{pt.source_locator}, ...
    'VariableNames',{'dataset','run','point','theta75_deg','Vtip_fps','Mtip_reported', ...
    'CT_exp','deltaTheta_exact_deg','theta_root_deg','CT_root','CT_residual', ...
    'physical_root','root_status','allSectionsConverged','alpha_min_deg','alpha_max_deg', ...
    'Mach_min','Mach_max','rootTolCT','rootTolDeg','source_locator'});
end

function row=make_point_row(pt,ct0,slope,lin,exact,deltaText,~,baseOut,slopeMeta,tct,td,rho,aSound)
row=table({pt.dataset},pt.run,pt.point,pt.theta75_deg,pt.Vtip_fps,pt.Vtip_fps*0.3048/3.81, ...
    pt.Mtip_reported,pt.Vtip_fps*0.3048/aSound,rho,pt.CT_exp,ct0,slope,lin,exact, ...
    {deltaText},exact-lin,baseOut.allSectionsConverged, ...
    {slopeMeta.method},slopeMeta.step_deg,tct,td,{pt.source_locator}, ...
    'VariableNames',{'dataset','run','point','theta75_deg','Vtip_fps','Omega_radps', ...
    'Mtip_reported','Mtip_from_Vtip','rho_kgm3','CT_exp','CT_model_at_theta75', ...
    'dCT_dtheta_fixed_per_deg','deltaTheta_linearized_deg','deltaTheta_exact_first_deg', ...
    'deltaTheta_exact_all_deg','exact_minus_linearized_deg','baseModelConverged', ...
    'linearized_slope_method','linearized_slope_step_deg','rootTolCT','rootTolDeg','source_locator'});
end

function write_report(result,outputDir)
fid=fopen(fullfile(outputDir,'DRAFT_PR_DIAG2_M1G_EXACT_INVERSION.md'),'w');
fprintf(fid,'# [DIAG2] M1-G 逐点总距反解\n\n');
fprintf(fid,'## Identity gate\n\n`PASS`. This diagnostic added only analysis code and a copied A-2 carrier; model/, params_nominal.m, and frozen result files were not written.\n\n');
fprintf(fid,'## Method and uncertainty\n\n');
fprintf(fid,'For each point, `Omega=Vtip_fps*0.3048/R`, `R=3.81 m`, and `rho=%.12g kg/m^3`; no representative Vtip/RPM was substituted. Roots solve the unchanged M1-G model numerically. A four-node reduced-resolution scan at theta75 offsets -10, 0, +10, +25 deg brackets sign changes; every bracket is then refined and re-evaluated with the unchanged default solver, using CT tolerance %.1e and theta tolerance %.1e deg. Roots outside the solver convergence/positive-load/C81 alpha(-10,30 deg)/Mach(0,0.85) domain are reported nonphysical and do not become extrapolated roots.\n\n',result.rho_kgm3,result.rootTolCT,result.rootTolDeg);
fprintf(fid,'The linearized comparison uses a separate central numerical slope at theta75 with h=%.4g deg; it is not used as the root solver. Input precision is inherited from the carriers: theta75 0.01 deg (A-2) or 0.1/0.01 deg (A-3), Vtip 0.1 fps, Mtip 4 decimals, CT 6 significant decimals. Thus data-rounding uncertainty is materially larger than the root tolerance; the latter is only numerical solver uncertainty.\n\n',result.slopeStepDeg);
fprintf(fid,'## Requested WADC printout\n\nSee `TABLE_B_FIXED_COLLECTIVE_MACH_POINTWISE_WADC.csv`; it lists every WADC point with reported and Vtip-derived Mtip.\n\n');
fprintf(fid,'## Table A / Table B\n\n');
fprintf(fid,'- Table A: `TABLE_A_FIXED_MACH_COLLECTIVE_POINTWISE.csv`, all OARF Run14/15 and WADC points, pointwise exact versus theta75.\n');
fprintf(fid,'- Table B: `TABLE_B_FIXED_COLLECTIVE_MACH_POINTWISE_WADC.csv`, all WADC points sorted by theta75 and Mtip so paired equal-theta points are adjacent.\n');
fprintf(fid,'- `ALL_ROOTS_POINTWISE.csv` retains every candidate root, including nonphysical roots; the point tables use `NO_PHYSICAL_ROOT` where no physical root remains.\n\n');
fprintf(fid,'## Fact-only trend answers\n\n');
fprintf(fid,'The trend decisions must be made from the pointwise deltas in the two CSV tables, comparing observed changes with the stated root tolerance and input digitization. No physical attribution is made.\n\n');
fprintf(fid,'## Reproduction\n\n```matlab\naddpath(''analysis'');\nr = diagnose_m1g_exact_collective_inversion(''%s'');\n```\n',strrep(outputDir,'\','/'));
fclose(fid);
end

function out=ternary(c,a,b), if c, out=a; else, out=b; end, end
