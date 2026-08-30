function results = run_m1_stage4b_wake_solver_audit(outputDir)
%RUN_M1_STAGE4B_WAKE_SOLVER_AUDIT Numerical-only M1-F coupling audit.
%
% The Stage-4 M1-F1 run showed no fully converged 6-11 deg points. This
% runner does NOT change the aerodynamic or wake model. It changes only the
% nonlinear-solve initialization and iteration budget:
%
%   1) solve the same actual-geometry + C81 + generic Corrigan n=1 model
%      with uniform momentum inflow;
%   2) use that converged uniform inflow as the initial state of the exact
%      same Landgrebe/Biot-Savart wake coupling;
%   3) compare the production numerical relaxation 0.50 with predeclared
%      lower numerical relaxations 0.25 and 0.10;
%   4) allow 80 iterations only to determine mathematical convergence.
%
% Relaxation values are NUMERICAL solver controls. They are not selected by
% OARF CT/CP/FM error. All three are reported; no best-MAPE selection is
% permitted. A physically valid fixed point must agree across converged
% relaxations to numerical tolerance.

rootDir = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(rootDir,'results','m1_stage4b_wake_solver_audit');
end
if ~exist(outputDir,'dir'), mkdir(outputDir); end

Pbase = params_nominal();
R = 3.81;
rootCut = 0.0875;
collective75_deg = [6;7;8;9;10;11];
Vtip_fps = [768.4;768.4;768.4;768.0;768.0;767.7];
CT_exp = [0.009208;0.010104;0.011063;0.012035;0.013089;0.013929];
CP_exp = [0.000796;0.000913;0.001044;0.001188;0.001358;0.001523];
FM_exp = [0.7849;0.7866;0.7881;0.7858;0.7797;0.7632];

referenceChord_m = 14*0.0254;
sigmaLandgrebe = Pbase.rotor.Nb*referenceChord_m/(pi*R);
thetaTwEq_deg = nasa_metal_twist_deg(1.0)-nasa_metal_twist_deg(rootCut);
wakeTurns = 3.0;
segmentsPerRev = 36;
relaxList = [0.50;0.25;0.10];
maxIterAudit = 80;

Ptemplate = Pbase;
Ptemplate.rotor.R = R;
Ptemplate.rotor.Nb = 3;
Ptemplate.rotor.rootCut = rootCut;
Ptemplate.rotor.Ib = Ptemplate.rotor.bladeMass*R^2/3;
Ptemplate.rotor.Sblade = Ptemplate.rotor.bladeMass*R/2;
if ~isfield(Ptemplate.env,'aSound'), Ptemplate.env.aSound = 340.0; end

rows = table();
for k = 1:numel(collective75_deg)
    P = Ptemplate;
    Vtip_mps = Vtip_fps(k)*0.3048;
    P.rotor.Omega = Vtip_mps/R;

    % Numerical anchor only: same physics with uniform momentum inflow.
    anchor = solve_case(P,collective75_deg(k),'UNIFORM',sigmaLandgrebe, ...
        thetaTwEq_deg,wakeTurns,segmentsPerRev,0.50,40,[]);
    if ~anchor.physicalConverged
        error('run_m1_stage4b_wake_solver_audit:AnchorFailed', ...
            'Uniform momentum numerical anchor failed at %.3g deg.',collective75_deg(k));
    end
    initialVi = anchor.viRadial_mps;

    for ir = 1:numel(relaxList)
        out = solve_case(P,collective75_deg(k),'NONLOCAL',sigmaLandgrebe, ...
            thetaTwEq_deg,wakeTurns,segmentsPerRev,relaxList(ir),maxIterAudit,initialVi);
        A = pi*R^2;
        CT = out.thrust/(P.env.rho*A*Vtip_mps^2);
        CP = out.torque*P.rotor.Omega/(P.env.rho*A*Vtip_mps^3);
        if CT > 0 && CP > 0, FM = CT^(3/2)/(sqrt(2)*CP); else, FM = NaN; end
        one = table(collective75_deg(k),relaxList(ir),maxIterAudit, ...
            anchor.viAreaMean_mps,CT_exp(k),CT,100*(CT-CT_exp(k))/CT_exp(k), ...
            CP_exp(k),CP,100*(CP-CP_exp(k))/CP_exp(k),FM_exp(k),FM, ...
            100*(FM-FM_exp(k))/FM_exp(k),out.physicalConverged,out.iterations, ...
            out.finalUpdateResidual,out.finalFlapResidual,out.rawWakeMean_mps, ...
            out.viAreaMean_mps,out.viMin_mps,out.viMax_mps,out.viCV, ...
            out.momentumMeanClosureRelative,{out.failureCode}, ...
            'VariableNames',{'collective75_deg','inducedRelax','maxIterations', ...
            'uniformAnchorVi_mps','CT_exp','CT_model','CT_relativeError_pct', ...
            'CP_exp','CP_model','CP_relativeError_pct','FM_exp','FM_model', ...
            'FM_relativeError_pct','physicalConverged','iterations', ...
            'finalUpdateResidual','finalFlapResidual','rawWakeMean_mps', ...
            'viAreaMean_mps','viMin_mps','viMax_mps','viCV', ...
            'momentumMeanClosureRelative','failureCode'});
        rows = [rows;one]; %#ok<AGROW>
    end
end
writetable(rows,fullfile(outputDir,'M1_STAGE4B_WAKE_SOLVER_POINTS.csv'));

summary = table();
for ir = 1:numel(relaxList)
    mask = rows.inducedRelax == relaxList(ir);
    conv = mask & rows.physicalConverged;
    complete = sum(conv)==numel(collective75_deg);
    if any(conv)
        ctMape=mean(abs(rows.CT_relativeError_pct(conv)));
        cpMape=mean(abs(rows.CP_relativeError_pct(conv)));
        fmMape=mean(abs(rows.FM_relativeError_pct(conv)));
        maxResidual=max(rows.finalUpdateResidual(conv));
    else
        ctMape=NaN; cpMape=NaN; fmMape=NaN; maxResidual=NaN;
    end
    one=table(relaxList(ir),sum(conv),complete,ctMape,cpMape,fmMape,maxResidual, ...
        'VariableNames',{'inducedRelax','convergedPointCount','completeFixedWindow', ...
        'CT_MAPE_converged_pct','CP_MAPE_converged_pct','FM_MAPE_converged_pct', ...
        'maxFinalUpdateResidual_converged'});
    summary=[summary;one]; %#ok<AGROW>
end
writetable(summary,fullfile(outputDir,'M1_STAGE4B_WAKE_SOLVER_SUMMARY.csv'));

% Cross-relaxation agreement is a numerical criterion, not a data-fit test.
agreement = table();
for k=1:numel(collective75_deg)
    mask=rows.collective75_deg==collective75_deg(k) & rows.physicalConverged;
    if sum(mask)>=2
        ctSpread=100*(max(rows.CT_model(mask))-min(rows.CT_model(mask)))/mean(rows.CT_model(mask));
        cpSpread=100*(max(rows.CP_model(mask))-min(rows.CP_model(mask)))/mean(rows.CP_model(mask));
        viSpread=100*(max(rows.viAreaMean_mps(mask))-min(rows.viAreaMean_mps(mask)))/mean(rows.viAreaMean_mps(mask));
    else
        ctSpread=NaN; cpSpread=NaN; viSpread=NaN;
    end
    agreement=[agreement;table(collective75_deg(k),sum(mask),ctSpread,cpSpread,viSpread, ...
        'VariableNames',{'collective75_deg','convergedRelaxationCount', ...
        'CT_crossRelaxSpread_pct','CP_crossRelaxSpread_pct','viMean_crossRelaxSpread_pct'})]; %#ok<AGROW>
end
writetable(agreement,fullfile(outputDir,'M1_STAGE4B_WAKE_SOLVER_AGREEMENT.csv'));

metadataName={'model_identity';'physics_changed_from_M1_F1';'initialization'; ...
    'relaxation_values';'max_iterations';'selection_by_OARF_error'; ...
    'success_criterion';'claim_boundary'};
metadataValue={'M1_F_NUMERICAL_COUPLING_AUDIT';'NO'; ...
    'CONVERGED_UNIFORM_MOMENTUM_SAME_POINT';'0.50_0.25_0.10'; ...
    sprintf('%d',maxIterAudit);'NO'; ...
    'FIXED_POINT_RESIDUAL_AND_CROSS_RELAXATION_AGREEMENT_ONLY'; ...
    'NUMERICAL_SOLVER_AUDIT_NOT_NEW_PHYSICAL_MODEL'};
writetable(table(metadataName,metadataValue), ...
    fullfile(outputDir,'M1_STAGE4B_WAKE_SOLVER_METADATA.csv'));

results=struct(); results.points=rows; results.summary=summary; results.agreement=agreement;
results.claimBoundary='M1_F_NUMERICAL_SOLVER_AUDIT_NO_PHYSICS_CHANGE_NO_OARF_SELECTION';
save(fullfile(outputDir,'M1_STAGE4B_WAKE_SOLVER_RESULTS.mat'),'results');
end

function out=solve_case(P,theta75_deg,mode,sigmaLandgrebe,thetaTwEq_deg,wakeTurns,segmentsPerRev,relax,maxIter,initialVi)
R=P.rotor.R; Omega=P.rotor.Omega; tipSpeed=Omega*R; rho=P.env.rho; A=pi*R^2;
r0=P.rotor.rootCut*R; rEdges=linspace(r0,R,P.rotor.nRadial+1);
rMid=0.5*(rEdges(1:end-1)+rEdges(2:end)); dr=diff(rEdges); x=rMid/R;
psi=((0:P.rotor.nAzimuth-1)*(2*pi/P.rotor.nAzimuth)).';
chord_in=14*ones(size(x)); qi=x<=0.25; chord_in(qi)=-18.4615*x(qi)+18.6154;
chord_m=chord_in*0.0254; thetaSource_deg=nasa_metal_twist_deg(x);
theta75Source_deg=nasa_metal_twist_deg(0.75);
thetaBlade=(theta75_deg+thetaSource_deg-theta75Source_deg)*pi/180;
UT=Omega*rMid; areaWeights=rMid.*dr;
if isempty(initialVi)
    vi0=sqrt(max(P.mass.m*P.env.g/2,1)/(2*rho*A)); viRadial=vi0*ones(size(rMid));
else
    viRadial=initialVi(:).';
end
zFlap=P.rotor.flapInitial(:); converged=false; failureCode='NOT_CONVERGED';
rawWakeMean=NaN; finalUpdateResidual=Inf; finalFlapResidual=Inf;
for iter=1:maxIter
    [zFlap,flapInfo]=solve_flap(viRadial,zFlap); finalFlapResidual=flapInfo.residualNorm;
    if ~flapInfo.converged, failureCode='FLAP_NOT_CONVERGED'; break; end
    loads=blade_loads(viRadial,zFlap);
    if ~(isfinite(loads.T)&&loads.T>0), failureCode='NONPOSITIVE_THRUST'; break; end
    viMomentum=sqrt(loads.T/(2*rho*A));
    if strcmp(mode,'UNIFORM')
        viTarget=viMomentum*ones(size(viRadial)); rawWakeMean=viMomentum;
    else
        CTstd=loads.T/(rho*A*tipSpeed^2);
        [rawWake,~]=xv15_landgrebe_biot_savart_inflow(rMid,rEdges,loads.gammaMean, ...
            CTstd,sigmaLandgrebe,thetaTwEq_deg,P.rotor.Nb,R,wakeTurns,segmentsPerRev);
        rawWakeMean=sum(rawWake.*areaWeights)/sum(areaWeights);
        if ~(isfinite(rawWakeMean)&&rawWakeMean>0)
            failureCode='RAW_WAKE_MEAN_NONPOSITIVE_DURING_ITERATION'; break;
        end
        viTarget=viMomentum*(rawWake/rawWakeMean);
    end
    viNew=(1-relax)*viRadial+relax*viTarget;
    finalUpdateResidual=max(abs(viNew-viRadial))/max(1,max(abs(viRadial)));
    viRadial=viNew;
    if finalUpdateResidual<P.rotor.inducedTol && flapInfo.residualNorm<=P.rotor.flapResidualTol
        converged=true; failureCode='SUPPORTED'; break;
    end
end
[zFlap,flapInfo]=solve_flap(viRadial,zFlap); loads=blade_loads(viRadial,zFlap);
finalFlapResidual=flapInfo.residualNorm;
viMomentum=sqrt(max(loads.T,0)/(2*rho*A)); viAreaMean=sum(viRadial.*areaWeights)/sum(areaWeights);
meanClosure=abs(viAreaMean-viMomentum)/max(viMomentum,1e-12);
physical=converged&&flapInfo.converged&&loads.T>0&&meanClosure<=5e-3;
if ~physical&&strcmp(failureCode,'SUPPORTED'), failureCode='FINAL_CLOSURE_OR_PHYSICAL_CHECK_FAILED'; end
out=struct('thrust',loads.T,'torque',loads.Q,'physicalConverged',physical,'iterations',iter, ...
    'finalUpdateResidual',finalUpdateResidual,'finalFlapResidual',finalFlapResidual, ...
    'rawWakeMean_mps',rawWakeMean,'viMomentum_mps',viMomentum,'viAreaMean_mps',viAreaMean, ...
    'viMin_mps',min(viRadial),'viMax_mps',max(viRadial), ...
    'viCV',std(viRadial)/max(abs(mean(viRadial)),1e-12), ...
    'momentumMeanClosureRelative',meanClosure,'failureCode',failureCode,'viRadial_mps',viRadial);

    function [z,info]=solve_flap(viNow,z0)
        z=z0(:); info=struct('converged',false,'iterations',0,'residualNorm',Inf);
        for kk=1:P.rotor.flapMaxIter
            [res,scale]=flap_residual(z,viNow); rn=res/scale;
            if norm(rn)<=P.rotor.flapResidualTol
                info.converged=true; info.iterations=kk; info.residualNorm=norm(rn); return;
            end
            J=zeros(3,3);
            for jj=1:3
                h=P.rotor.flapJacobianStep*max(1,abs(z(jj))); zp=z; zm=z;
                zp(jj)=zp(jj)+h; zm(jj)=zm(jj)-h;
                [rp,~]=flap_residual(zp,viNow); [rm,~]=flap_residual(zm,viNow);
                J(:,jj)=(rp-rm)/(2*h*scale);
            end
            if ~all(isfinite(J(:)))||rcond(J.'*J)<1e-14, return; end
            dz=-(J.'*J+P.rotor.flapNewtonRegularization*eye(3))\(J.'*rn);
            step=1; accepted=false;
            for trial=1:P.rotor.flapLineSearchMaxIter
                zc=z+step*dz; betaCheck=zc(1)+zc(2)*cos(psi)+zc(3)*sin(psi);
                if all(isfinite(zc))&&max(abs(betaCheck))<P.rotor.flapDivergenceAngle
                    [rc,sc]=flap_residual(zc,viNow);
                    if norm(rc/sc)<norm(rn), z=zc; accepted=true; break; end
                end
                step=step*P.rotor.flapNewtonDamping;
            end
            if ~accepted, return; end
        end
        [res,scale]=flap_residual(z,viNow); info.iterations=P.rotor.flapMaxIter; info.residualNorm=norm(res/scale);
    end
    function [res,scale]=flap_residual(z,viNow)
        ll=blade_loads(viNow,z); gravityMoment=-P.rotor.Sblade*P.env.g*cos(ll.beta);
        inertialRestoring=P.rotor.Ib*ll.betaDDot+P.rotor.Ib*Omega^2*ll.beta;
        byAz=inertialRestoring-ll.flapMomentByAzimuth-gravityMoment;
        res=[mean(byAz);2*mean(byAz.*cos(psi));2*mean(byAz.*sin(psi))];
        scale=max([max(abs(ll.flapMomentByAzimuth)),max(abs(gravityMoment)),P.rotor.Ib*Omega^2*0.05,1]);
    end
    function ll=blade_loads(viNow,z)
        betaLocal=z(1)+z(2)*cos(psi)+z(3)*sin(psi);
        betaDotLocal=-Omega*(-z(2)*sin(psi)+z(3)*cos(psi));
        betaDDotLocal=-Omega^2*(z(2)*cos(psi)+z(3)*sin(psi));
        viField=ones(P.rotor.nAzimuth,1)*viNow; UP=viField-betaDotLocal.*rMid;
        W=hypot(UT,UP); phi=atan2(UP,max(abs(UT),1e-8)); alpha=thetaBlade-phi;
        Mach=W/P.env.aSound; chordField=ones(size(alpha)).*chord_m; rField=ones(size(alpha)).*x;
        [CL,CD,meta]=xv15_c81_corrigan_stall_delay(alpha,Mach,rField,chordField,R,'CORRIGAN_GENERIC_N1');
        q=0.5*rho*W.^2; dL=q.*chord_m.*CL.*dr; dD=q.*chord_m.*CD.*dr;
        dT=dL.*cos(phi)-dD.*sin(phi); dH=dD.*cos(phi)+dL.*sin(phi); dQ=dH.*rMid;
        factor=P.rotor.Nb/P.rotor.nAzimuth; ll.T=sum(factor*sum(dT,1)); ll.Q=sum(factor*sum(dQ,1));
        ll.flapMomentByAzimuth=sum(dT.*rMid,2); ll.beta=betaLocal; ll.betaDDot=betaDDotLocal;
        ll.gammaMean=mean(0.5*W.*chord_m.*CL,1);
        ll.alphaClampCount=meta.alphaClampCount; ll.machClampCount=meta.machClampCount;
    end
end
