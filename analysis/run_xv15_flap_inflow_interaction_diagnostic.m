function results = run_xv15_flap_inflow_interaction_diagnostic(outputDir)
%RUN_XV15_FLAP_INFLOW_INTERACTION_DIAGNOSTIC
% Factorial hover diagnostic for first-harmonic flapping x azimuthal inflow.
%
% Four combinations are compared while actual XV-15 metal-blade radial
% chord/twist, scalar C81 section aerodynamics and global mean-momentum
% closure are frozen:
%
%   1) Eq. (12) azimuthal inflow + current first-harmonic flapping;
%   2) Eq. (12) azimuthal inflow + locked blade (beta=0);
%   3) uniform azimuthal inflow + current first-harmonic flapping;
%   4) uniform azimuthal inflow + locked blade.
%
% This separates the direct first-harmonic flapping effect from its
% interaction with the Eq. (12) inflow harmonic. OARF CT/CP/FM are external
% comparison data only and are not used to fit any parameter.

rootDir = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(rootDir,'results','xv15_section_aero_validation');
end
if ~exist(outputDir,'dir'); mkdir(outputDir); end

Pbase = params_nominal();
scalarC81 = build_xv15_c81_low_order_section_aero();
R = 3.81;
rootCut = 0.0875;
Ptemplate = Pbase;
Ptemplate.rotor.R = R;
Ptemplate.rotor.Nb = 3;
Ptemplate.rotor.rootCut = rootCut;
Ptemplate.rotor.Ib = Ptemplate.rotor.bladeMass*R^2/3;
Ptemplate.rotor.Sblade = Ptemplate.rotor.bladeMass*R/2;
Ptemplate.rotor.nRadial = 48;

theta75Source_deg = nasa_metal_twist_deg(0.75);
collective75_deg = [6;7;8;9;10;11];
Vtip_fps = [768.4;768.4;768.4;768.0;768.0;767.7];
CT_exp = [0.009208;0.010104;0.011063;0.012035;0.013089;0.013929];
CP_exp = [0.000796;0.000913;0.001044;0.001188;0.001358;0.001523];
FM_exp = [0.7849;0.7866;0.7881;0.7858;0.7797;0.7632];

rows = table();
for k = 1:numel(collective75_deg)
    P = Ptemplate;
    Vtip_mps = Vtip_fps(k)*0.3048;
    P.rotor.Omega = Vtip_mps/R;

    A = solve_case(P,collective75_deg(k),theta75Source_deg,scalarC81,'EQ12','FULL_FLAP');
    B = solve_case(P,collective75_deg(k),theta75Source_deg,scalarC81,'EQ12','LOCKED');
    C = solve_case(P,collective75_deg(k),theta75Source_deg,scalarC81,'UNIFORM','FULL_FLAP');
    D = solve_case(P,collective75_deg(k),theta75Source_deg,scalarC81,'UNIFORM','LOCKED');

    diskArea = pi*R^2;
    denT = P.env.rho*diskArea*Vtip_mps^2;
    denP = P.env.rho*diskArea*Vtip_mps^3;
    [CTA,CPA,FMA] = coeffs(A,denT,denP,P.rotor.Omega);
    [CTB,CPB,FMB] = coeffs(B,denT,denP,P.rotor.Omega);
    [CTC,CPC,FMC] = coeffs(C,denT,denP,P.rotor.Omega);
    [CTD,CPD,FMD] = coeffs(D,denT,denP,P.rotor.Omega);

    one = table(collective75_deg(k),CT_exp(k),CTA,CTB,CTC,CTD, ...
        CP_exp(k),CPA,CPB,CPC,CPD,FM_exp(k),FMA,FMB,FMC,FMD, ...
        A.zFlap(1)*180/pi,A.zFlap(2)*180/pi,A.zFlap(3)*180/pi, ...
        C.zFlap(1)*180/pi,C.zFlap(2)*180/pi,C.zFlap(3)*180/pi, ...
        'VariableNames',{'collective75_deg','CT_exp','CT_eq12_full','CT_eq12_locked', ...
        'CT_uniform_full','CT_uniform_locked','CP_exp','CP_eq12_full', ...
        'CP_eq12_locked','CP_uniform_full','CP_uniform_locked','FM_exp', ...
        'FM_eq12_full','FM_eq12_locked','FM_uniform_full','FM_uniform_locked', ...
        'beta0_eq12_deg','beta1c_eq12_deg','beta1s_eq12_deg', ...
        'beta0_uniform_deg','beta1c_uniform_deg','beta1s_uniform_deg'});
    rows = [rows;one]; %#ok<AGROW>
end
writetable(rows,fullfile(outputDir,'XV15_FLAP_INFLOW_INTERACTION_MATLAB_DIAGNOSTIC.csv'));

allMask = true(height(rows),1);
highMask = rows.collective75_deg >= 9;
metrics = table();
metrics.CT_MAPE_eq12_full_6to11_pct = mape(rows.CT_eq12_full,rows.CT_exp,allMask);
metrics.CT_MAPE_eq12_locked_6to11_pct = mape(rows.CT_eq12_locked,rows.CT_exp,allMask);
metrics.CT_MAPE_uniform_full_6to11_pct = mape(rows.CT_uniform_full,rows.CT_exp,allMask);
metrics.CT_MAPE_uniform_locked_6to11_pct = mape(rows.CT_uniform_locked,rows.CT_exp,allMask);
metrics.CP_MAPE_eq12_full_6to11_pct = mape(rows.CP_eq12_full,rows.CP_exp,allMask);
metrics.CP_MAPE_eq12_locked_6to11_pct = mape(rows.CP_eq12_locked,rows.CP_exp,allMask);
metrics.CP_MAPE_uniform_full_6to11_pct = mape(rows.CP_uniform_full,rows.CP_exp,allMask);
metrics.CP_MAPE_uniform_locked_6to11_pct = mape(rows.CP_uniform_locked,rows.CP_exp,allMask);
metrics.CT_MAPE_eq12_full_9to11_pct = mape(rows.CT_eq12_full,rows.CT_exp,highMask);
metrics.CT_MAPE_eq12_locked_9to11_pct = mape(rows.CT_eq12_locked,rows.CT_exp,highMask);
metrics.CT_MAPE_uniform_full_9to11_pct = mape(rows.CT_uniform_full,rows.CT_exp,highMask);
metrics.CT_MAPE_uniform_locked_9to11_pct = mape(rows.CT_uniform_locked,rows.CT_exp,highMask);
metrics.CP_MAPE_eq12_full_9to11_pct = mape(rows.CP_eq12_full,rows.CP_exp,highMask);
metrics.CP_MAPE_eq12_locked_9to11_pct = mape(rows.CP_eq12_locked,rows.CP_exp,highMask);
metrics.CP_MAPE_uniform_full_9to11_pct = mape(rows.CP_uniform_full,rows.CP_exp,highMask);
metrics.CP_MAPE_uniform_locked_9to11_pct = mape(rows.CP_uniform_locked,rows.CP_exp,highMask);
writetable(metrics,fullfile(outputDir,'XV15_FLAP_INFLOW_INTERACTION_MATLAB_METRICS.csv'));

results = struct('table',rows,'metrics',metrics, ...
    'claimBoundary',['FACTORIAL_FLAP_X_AZIMUTHAL_INFLOW_DIAGNOSTIC_' ...
    'ACTUAL_RADIAL_GEOMETRY_SCALAR_C81_NO_OARF_FIT_NO_PRODUCTION_CHANGE']);
save(fullfile(outputDir,'XV15_FLAP_INFLOW_INTERACTION_RESULTS.mat'),'results');
end

function out = solve_case(P,theta75_deg,theta75Source_deg,scalarC81,inflowMode,flapMode)
R=P.rotor.R; Omega=P.rotor.Omega; Vtip=Omega*R; rho=P.env.rho; A=pi*R^2;
r0=P.rotor.rootCut*R; edges=linspace(r0,R,P.rotor.nRadial+1);
r=0.5*(edges(1:end-1)+edges(2:end)); dr=diff(edges); x=r/R;
psi=((0:P.rotor.nAzimuth-1)*(2*pi/P.rotor.nAzimuth)).';
chord=xv15_metal_chord_m(x);
theta=(theta75_deg+nasa_metal_twist_deg(x)-theta75Source_deg)*pi/180;
UT=Omega*r;

vi=sqrt(max(P.mass.m*P.env.g/2,1)/(2*rho*A));
z=P.rotor.flapInitial(:); converged=false; viError=Inf;
for iter=1:max(100,5*P.rotor.inducedMaxIter)
    if strcmp(flapMode,'LOCKED')
        z=zeros(3,1); flapOK=true; flapNorm=0;
    else
        [z,flapOK,flapNorm]=solve_flap(vi,z);
    end
    if ~flapOK; break; end
    loads=blade_loads(vi,z);
    lambda1=-vi/max(Vtip,eps);
    CTiter=max(loads.T,0)/(0.5*rho*A*Vtip^2);
    viTarget=Vtip*CTiter/(4*max(abs(lambda1),1e-12));
    viNew=0.5*(vi+viTarget);
    viError=abs(viNew-vi)/max(1,abs(vi)); vi=viNew;
    if viError<1e-6 && flapNorm<=P.rotor.flapResidualTol
        converged=true; break;
    end
end
loads=blade_loads(vi,z);
out=struct('thrust',loads.T,'torque',loads.Q,'inducedVelocity',vi, ...
    'zFlap',z,'converged',converged,'iterations',iter);

    function [zNow,ok,rn] = solve_flap(viNow,z0)
        zNow=z0(:); ok=false; rn=Inf;
        for kk=1:P.rotor.flapMaxIter
            [res,scale]=flap_residual(zNow,viNow); rn=norm(res/scale);
            if rn<=P.rotor.flapResidualTol; ok=true; return; end
            J=zeros(3,3);
            for jj=1:3
                h=P.rotor.flapJacobianStep*max(1,abs(zNow(jj)));
                zp=zNow; zm=zNow; zp(jj)=zp(jj)+h; zm(jj)=zm(jj)-h;
                [rp,~]=flap_residual(zp,viNow); [rm,~]=flap_residual(zm,viNow);
                J(:,jj)=(rp-rm)/(2*h*scale);
            end
            if ~all(isfinite(J(:))) || rcond(J.'*J)<1e-14; return; end
            dz=-(J.'*J+P.rotor.flapNewtonRegularization*eye(3))\(J.'*(res/scale));
            step=1; accepted=false;
            for trial=1:P.rotor.flapLineSearchMaxIter
                zc=zNow+step*dz;
                beta=zc(1)+zc(2)*cos(psi)+zc(3)*sin(psi);
                if all(isfinite(zc)) && max(abs(beta))<P.rotor.flapDivergenceAngle
                    [rc,sc]=flap_residual(zc,viNow);
                    if norm(rc/sc)<rn; zNow=zc; accepted=true; break; end
                end
                step=step*P.rotor.flapNewtonDamping;
            end
            if ~accepted; return; end
        end
    end

    function [res,scale] = flap_residual(zNow,viNow)
        L=blade_loads(viNow,zNow);
        gravity=-P.rotor.Sblade*P.env.g*cos(L.beta);
        inertial=P.rotor.Ib*L.betaDDot+P.rotor.Ib*Omega^2*L.beta;
        by=inertial-L.flapMomentByAzimuth-gravity;
        res=[mean(by);2*mean(by.*cos(psi));2*mean(by.*sin(psi))];
        scale=max([max(abs(L.flapMomentByAzimuth)),max(abs(gravity)), ...
            P.rotor.Ib*Omega^2*0.05,1]);
    end

    function L = blade_loads(viNow,zNow)
        beta=zNow(1)+zNow(2)*cos(psi)+zNow(3)*sin(psi);
        betaDot=-Omega*(-zNow(2)*sin(psi)+zNow(3)*cos(psi));
        betaDDot=-Omega^2*(zNow(2)*cos(psi)+zNow(3)*sin(psi));
        if strcmp(inflowMode,'EQ12')
            viField=viNow.*(1+cos(psi).*(r/R));
        else
            viField=viNow+zeros(numel(psi),numel(r));
        end
        UP=viField-betaDot.*r;
        W=hypot(UT,UP); phi=atan2(UP,max(abs(UT),1e-8));
        alpha=theta-phi;
        CL=scalarC81.CLmax*tanh(scalarC81.liftSlope*(alpha-scalarC81.alpha0L_rad)/scalarC81.CLmax);
        CD=scalarC81.CD0+scalarC81.kCD*CL.^2;
        q=0.5*rho*W.^2;
        dL=q.*chord.*CL.*dr; dD=q.*chord.*CD.*dr;
        dT=dL.*cos(phi)-dD.*sin(phi); dH=dD.*cos(phi)+dL.*sin(phi);
        dQ=dH.*r; factor=P.rotor.Nb/P.rotor.nAzimuth;
        L.T=factor*sum(dT(:)); L.Q=factor*sum(dQ(:));
        L.flapMomentByAzimuth=sum(dT.*r,2); L.beta=beta; L.betaDDot=betaDDot;
    end
end

function [CT,CP,FM]=coeffs(out,denT,denP,Omega)
CT=out.thrust/denT; CP=out.torque*Omega/denP; FM=figure_of_merit(CT,CP);
end
function c=xv15_metal_chord_m(x)
cIn=14*ones(size(x)); mask=x<=0.25; cIn(mask)=-18.4615*x(mask)+18.6154; c=cIn*0.0254;
end
function theta=nasa_metal_twist_deg(x)
theta=289.98*x.^5-892.87*x.^4+987.06*x.^3-438.31*x.^2+15.695*x+32.057;
end
function v=figure_of_merit(CT,CP)
if CT>0 && CP>0; v=CT^(3/2)/(sqrt(2)*CP); else; v=NaN; end
end
function v=mape(model,expv,mask)
if ~any(mask); v=NaN; else; v=100*mean(abs((model(mask)-expv(mask))./expv(mask))); end
end
