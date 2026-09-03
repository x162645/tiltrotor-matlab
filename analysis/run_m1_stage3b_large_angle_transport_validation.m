function results = run_m1_stage3b_large_angle_transport_validation(outputDir)
%RUN_M1_STAGE3B_LARGE_ANGLE_TRANSPORT_VALIDATION
% Freeze the already-run M1-G large-angle local closure and transport it,
% without any retuning, to OARF Run 14 and WADC Runs 1-3.
%
% This runner is deliberately downstream of the Run-15 diagnostic.  Run 14
% is same-campaign external correlation, while WADC is cross-facility data.
% No collective offset, gain, loss-factor coefficient, Corrigan exponent,
% solver tolerance, point membership, or environmental parameter is selected
% from the target errors in this runner.

rootDir=fileparts(fileparts(mfilename('fullpath')));
if nargin<1 || isempty(outputDir)
    outputDir=fullfile(rootDir,'results','m1_stage3b_large_angle_transport_validation');
end
if ~exist(outputDir,'dir'), mkdir(outputDir); end

Pbase=params_nominal(); R=3.81; rootCut=0.0875;
Ptemplate=Pbase; Ptemplate.rotor.R=R; Ptemplate.rotor.Nb=3; Ptemplate.rotor.rootCut=rootCut;
Ptemplate.rotor.Ib=Ptemplate.rotor.bladeMass*R^2/3;
Ptemplate.rotor.Sblade=Ptemplate.rotor.bladeMass*R/2;
if ~isfield(Ptemplate.env,'aSound'), Ptemplate.env.aSound=340.0; end

%% 1. Fail-closed identity gates on the already executed Run-15 definitions.
stage3=run_m1_stage3_corrigan_stall_delay(fullfile(outputDir,'identity_m1e_stage3'));
eMask=strcmp(stage3.points.mode,'CORRIGAN_GENERIC_N1'); eRef=stage3.points(eMask,:);
if height(eRef)~=6, error('Expected six frozen M1-E reference points.'); end
idE=table();
for k=1:height(eRef)
    P=Ptemplate; Vtip=eRef.Vtip_fps(k)*0.3048; P.rotor.Omega=Vtip/R;
    o=solve_xv15_m1e_frozen_hover_point(P,eRef.collective75_deg(k));
    [CT,CP,FM]=nondim(o,P,Vtip);
    idE=[idE;table(eRef.collective75_deg(k),abs(CT-eRef.CT_model(k)), ...
        abs(CP-eRef.CP_model(k)),abs(FM-eRef.FM_model(k)),o.physicalConverged, ...
        'VariableNames',{'collective75_deg','CT_absDiff','CP_absDiff','FM_absDiff','physicalConverged'})]; %#ok<AGROW>
end
maxIdE=max([idE.CT_absDiff;idE.CP_absDiff;idE.FM_absDiff]);
if ~all(idE.physicalConverged) || maxIdE>1e-10
    error('run_m1_stage3b_large_angle_transport_validation:M1EIdentityDrift', ...
        'Standalone M1-E helper drifted from frozen Stage-3; max diff %.12g.',maxIdE);
end
writetable(idE,fullfile(outputDir,'M1_STAGE3B_TRANSPORT_M1E_IDENTITY.csv'));

stage3b=run_m1_stage3b_large_angle_local_closure(fullfile(outputDir,'identity_m1g_run15'));
gRef=stage3b.points;
idG=table();
for k=1:height(gRef)
    P=Ptemplate; Vtip=gRef.Vtip_fps(k)*0.3048; P.rotor.Omega=Vtip/R;
    o=solve_xv15_m1g_large_angle_hover_point(P,gRef.collective75_deg(k),'CORRIGAN_GENERIC_N1',struct());
    [CT,CP,FM]=nondim(o,P,Vtip);
    idG=[idG;table(gRef.collective75_deg(k),abs(CT-gRef.CT_model(k)), ...
        abs(CP-gRef.CP_model(k)),abs(FM-gRef.FM_model(k)),o.physicalConverged, ...
        'VariableNames',{'collective75_deg','CT_absDiff','CP_absDiff','FM_absDiff','physicalConverged'})]; %#ok<AGROW>
end
maxIdG=max([idG.CT_absDiff;idG.CP_absDiff;idG.FM_absDiff]);
if ~all(idG.physicalConverged) || maxIdG>1e-10
    error('run_m1_stage3b_large_angle_transport_validation:M1GIdentityDrift', ...
        'Standalone M1-G helper drifted from first Run-15 execution; max diff %.12g.',maxIdG);
end
writetable(idG,fullfile(outputDir,'M1_STAGE3B_TRANSPORT_M1G_IDENTITY.csv'));

%% 2. OARF Run 14, fixed 6--11 deg window, same campaign as Run 15.
r14Collective=[6;7;8;9;10;11];
r14Vtip=[768.7;768.7;768.4;768.4;768.0;767.7];
r14CT=[0.009022;0.010095;0.010960;0.011985;0.013014;0.013978];
r14CP=[0.000815;0.000942;0.001076;0.001242;0.001427;0.001615];
r14FM=[0.7435;0.7614;0.7540;0.7470;0.7357;0.7236];
rows=table(); diagRows=table();
for k=1:numel(r14Collective)
    P=Ptemplate; Vtip=r14Vtip(k)*0.3048; P.rotor.Omega=Vtip/R;
    [pair,diagOne]=evaluate_pair(P,Vtip,r14Collective(k),r14CT(k),r14CP(k),r14FM(k), ...
        'OARF_RUN14_SAME_CAMPAIGN_EXTERNAL_CORRELATION',14,k,NaN);
    rows=[rows;pair]; diagRows=[diagRows;diagOne]; %#ok<AGROW>
end

%% 3. WADC Runs 1--3, inherited 6--11 deg window; no interpolation.
dataFile=fullfile(rootDir,'analysis','data','xv15_wadc_metal_table_a3.csv');
D=readtable(dataFile);
sel=ismember(D.run,[1;2;3]) & D.collective75_deg>=6 & D.collective75_deg<=11;
V=D(sel,:);
if height(V)~=15
    error('run_m1_stage3b_large_angle_transport_validation:WADCPointCount', ...
        'Expected 15 WADC transport points, got %d.',height(V));
end
for k=1:height(V)
    P=Ptemplate; Vtip=V.Vtip_fps(k)*0.3048; P.rotor.Omega=Vtip/R;
    [pair,diagOne]=evaluate_pair(P,Vtip,V.collective75_deg(k),V.CT_exp(k),V.CP_exp(k),V.FM_exp(k), ...
        'WADC_CROSS_FACILITY_POST_M1G_FREEZE_TRANSPORT',V.run(k),V.point(k),V.Mtip(k));
    rows=[rows;pair]; diagRows=[diagRows;diagOne]; %#ok<AGROW>
end
writetable(rows,fullfile(outputDir,'M1_STAGE3B_TRANSPORT_POINTS.csv'));
writetable(diagRows,fullfile(outputDir,'M1_STAGE3B_TRANSPORT_M1G_DIAGNOSTICS.csv'));

%% 4. Metrics and paired deltas.  All supported points are retained.
metrics=table();
datasets={'OARF_RUN14_SAME_CAMPAIGN_EXTERNAL_CORRELATION';'WADC_CROSS_FACILITY_POST_M1G_FREEZE_TRANSPORT'};
expected=[6;15]; models={'M1_E_FROZEN_CORRIGAN_N1';'M1_G_LARGE_ANGLE_LOCAL_CLOSURE'};
for id=1:numel(datasets)
    for im=1:numel(models)
        candidate=strcmp(rows.datasetRole,datasets{id}) & strcmp(rows.modelIdentity,models{im});
        metrics=[metrics;metric_row(rows,candidate,datasets{id},models{im},expected(id))]; %#ok<AGROW>
    end
end
writetable(metrics,fullfile(outputDir,'M1_STAGE3B_TRANSPORT_METRICS.csv'));

comparison=table();
for id=1:numel(datasets)
    a=metrics(strcmp(metrics.datasetRole,datasets{id}) & strcmp(metrics.modelIdentity,models{1}),:);
    b=metrics(strcmp(metrics.datasetRole,datasets{id}) & strcmp(metrics.modelIdentity,models{2}),:);
    comparison=[comparison;table(datasets(id),a.completeWindow && b.completeWindow, ...
        a.CT_MAPE_pct,b.CT_MAPE_pct,b.CT_MAPE_pct-a.CT_MAPE_pct, ...
        a.CP_MAPE_pct,b.CP_MAPE_pct,b.CP_MAPE_pct-a.CP_MAPE_pct, ...
        a.FM_MAPE_pct,b.FM_MAPE_pct,b.FM_MAPE_pct-a.FM_MAPE_pct, ...
        'VariableNames',{'datasetRole','completePair','M1E_CT_MAPE_pct','M1G_CT_MAPE_pct','M1GminusM1E_CT_pp', ...
        'M1E_CP_MAPE_pct','M1G_CP_MAPE_pct','M1GminusM1E_CP_pp','M1E_FM_MAPE_pct','M1G_FM_MAPE_pct','M1GminusM1E_FM_pp'})]; %#ok<AGROW>
end
writetable(comparison,fullfile(outputDir,'M1_STAGE3B_TRANSPORT_COMPARISON.csv'));

metadataName={'model_change_after_run15_result';'parameter_fit_to_run14';'parameter_fit_to_wadc'; ...
    'point_selection_after_targets';'collective_offset_fit';'gain_fit';'corrigan_exponent_change'; ...
    'loss_factor_tuning';'m1e_identity_max_abs_diff';'m1g_identity_max_abs_diff'; ...
    'run14_role';'wadc_role';'scientific_boundary'};
metadataValue={'NO';'NO';'NO';'NO';'NO';'NO';'NO';'NO';sprintf('%.12g',maxIdE);sprintf('%.12g',maxIdG); ...
    'SAME_OARF_CAMPAIGN_EXTERNAL_CORRELATION_NOT_INDEPENDENT_FACILITY'; ...
    'CROSS_FACILITY_TRANSPORT_AFTER_M1G_DEFINITION_FROZEN'; ...
    'ANALYSIS_ONLY_STEADY_AXIAL_LOCAL_CLOSURE_NOT_PRODUCTION_NOT_NONLOCAL_WAKE'};
writetable(table(metadataName,metadataValue),fullfile(outputDir,'M1_STAGE3B_TRANSPORT_METADATA.csv'));

results=struct('points',rows,'diagnostics',diagRows,'metrics',metrics,'comparison',comparison, ...
    'm1eIdentity',idE,'m1gIdentity',idG,'maxM1EIdentityDiff',maxIdE,'maxM1GIdentityDiff',maxIdG);
save(fullfile(outputDir,'M1_STAGE3B_TRANSPORT_RESULTS.mat'),'results');

    function [pair,diagOne]=evaluate_pair(P,Vtip,theta75,ctExp,cpExp,fmExp,datasetRole,runId,pointId,Mtip)
        e=solve_xv15_m1e_frozen_hover_point(P,theta75);
        g=solve_xv15_m1g_large_angle_hover_point(P,theta75,'CORRIGAN_GENERIC_N1',struct());
        pair=[point_row(e,P,Vtip,theta75,ctExp,cpExp,fmExp,datasetRole,runId,pointId,Mtip); ...
              point_row(g,P,Vtip,theta75,ctExp,cpExp,fmExp,datasetRole,runId,pointId,Mtip)];
        finitePhi=g.phi_rad(isfinite(g.phi_rad)); finiteAlpha=g.alpha_rad(isfinite(g.alpha_rad));
        finiteVi=g.vi_mps(isfinite(g.vi_mps)); finiteSwirl=g.swirl_mps(isfinite(g.swirl_mps)); finiteF=g.F(isfinite(g.F));
        diagOne=table({datasetRole},runId,pointId,theta75,min(finitePhi)*180/pi,max(finitePhi)*180/pi, ...
            min(finiteAlpha)*180/pi,max(finiteAlpha)*180/pi,mean(finiteVi),max(finiteVi),mean(finiteSwirl),max(finiteSwirl), ...
            min(finiteF),max(finiteF),g.maxAbsRootResidual,g.allSectionsConverged, ...
            'VariableNames',{'datasetRole','run','point','collective75_deg','phiMin_deg','phiMax_deg', ...
            'alphaMin_deg','alphaMax_deg','viMean_mps','viMax_mps','swirlMean_mps','swirlMax_mps', ...
            'F_min','F_max','maxAbsRootResidual','allSectionsConverged'});
    end
end

function row=point_row(out,P,Vtip,theta75,ctExp,cpExp,fmExp,datasetRole,runId,pointId,Mtip)
[CT,CP,FM]=nondim(out,P,Vtip);
ctErr=100*(CT-ctExp)/ctExp; cpErr=100*(CP-cpExp)/cpExp; fmErr=100*(FM-fmExp)/fmExp;
row=table({out.modelIdentity},{datasetRole},runId,pointId,Mtip,theta75,Vtip/0.3048,ctExp,CT,ctErr,cpExp,CP,cpErr,fmExp,FM,fmErr, ...
    out.physicalConverged,{out.physicalStatus},out.inducedVelocity_mps,out.closureResidualRelative, ...
    'VariableNames',{'modelIdentity','datasetRole','run','point','Mtip_reported','collective75_deg','Vtip_fps', ...
    'CT_exp','CT_model','CT_relativeError_pct','CP_exp','CP_model','CP_relativeError_pct','FM_exp','FM_model', ...
    'FM_relativeError_pct','physicalConverged','physicalStatus','inducedVelocity_mps','closureResidualRelative'});
end

function one=metric_row(rows,candidate,datasetRole,modelIdentity,expected)
valid=candidate & rows.physicalConverged & isfinite(rows.CT_model) & rows.CT_model>0 & ...
    isfinite(rows.CP_model) & rows.CP_model>0 & isfinite(rows.FM_model);
count=sum(valid); complete=count==expected;
if count>0
    ct=rows.CT_relativeError_pct(valid); cp=rows.CP_relativeError_pct(valid); fm=rows.FM_relativeError_pct(valid);
    vals={mean(abs(ct)),mean(abs(cp)),mean(abs(fm)),mean(ct),mean(cp),mean(fm),max(abs(ct)),max(abs(cp)),max(abs(fm))};
else
    vals=repmat({NaN},1,9);
end
one=table({datasetRole},{modelIdentity},expected,count,complete,vals{1},vals{2},vals{3},vals{4},vals{5},vals{6},vals{7},vals{8},vals{9}, ...
    'VariableNames',{'datasetRole','modelIdentity','expectedPointCount','validPointCount','completeWindow', ...
    'CT_MAPE_pct','CP_MAPE_pct','FM_MAPE_pct','CT_meanSigned_pct','CP_meanSigned_pct','FM_meanSigned_pct', ...
    'CT_maxAbs_pct','CP_maxAbs_pct','FM_maxAbs_pct'});
end

function [CT,CP,FM]=nondim(out,P,Vtip)
A=pi*P.rotor.R^2; CT=out.thrust/(P.env.rho*A*Vtip^2);
CP=out.torque*P.rotor.Omega/(P.env.rho*A*Vtip^3);
if isfinite(CT) && isfinite(CP) && CT>0 && CP>0, FM=CT^(3/2)/(sqrt(2)*CP); else, FM=NaN; end
end
