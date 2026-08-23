function results = run_xv15_delta3_pitch_flap_screen(outputDir)
%RUN_XV15_DELTA3_PITCH_FLAP_SCREEN
% Screen the documented XV-15 pitch-flap kinematic coupling (delta3) as a
% possible source of the residual metal-blade hover CT bias.
%
% The explicit low-order blade-pitch form found in XV-15 literature is
%   theta_b = theta_cmd - Kp*beta,   Kp = tan(delta3), |delta3| ~= 15 deg.
% Different publications use opposite delta3 sign conventions. Therefore
% this diagnostic reports both coupling signs and, crucially, separates:
%
%   HARMONIC_GIMBAL_ONLY:
%       pitch feedback uses beta1c*cos(psi)+beta1s*sin(psi) only. This is the
%       physically preferred XV-15 gimbal interpretation because the real
%       rotor has fixed precone and gimbal tilt, whereas this repository's
%       generic beta0 is an articulated-style coning coordinate.
%
%   FULL_GENERIC_BETA_SENSITIVITY:
%       pitch feedback also includes beta0. This is retained only as a
%       bounding sensitivity because it mixes generic coning with the real
%       XV-15 gimbal coordinate.
%
% Actual radial chord/twist, scalar C81 section aerodynamics, Eq. (12)
% azimuthal inflow, first-harmonic flapping and global mean-momentum closure
% remain frozen. OARF CT/CP/FM are external comparison data only.

rootDir = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(rootDir,'results','xv15_section_aero_validation');
end
if ~exist(outputDir,'dir'); mkdir(outputDir); end

Pbase = params_nominal();
scalarC81 = build_xv15_c81_low_order_section_aero();
R = 3.81; rootCut = 0.0875;
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

K = tan(15*pi/180);
modeName = {'BASELINE','NOMINAL_FULL_BETA','NOMINAL_HARMONIC_ONLY', ...
    'REVERSED_FULL_BETA','REVERSED_HARMONIC_ONLY'};
kSign = [0,-K,-K,+K,+K];
useFullBeta = [false,true,false,true,false];

rows = table();
for k = 1:numel(collective75_deg)
    P = Ptemplate;
    Vtip_mps = Vtip_fps(k)*0.3048;
    P.rotor.Omega = Vtip_mps/R;
    outs = cell(1,numel(modeName));
    CT = zeros(1,numel(modeName)); CP = CT; FM = CT;
    for j = 1:numel(modeName)
        outs{j} = solve_case(P,collective75_deg(k),theta75Source_deg, ...
            scalarC81,kSign(j),useFullBeta(j));
        A = pi*R^2;
        CT(j) = outs{j}.thrust/(P.env.rho*A*Vtip_mps^2);
        CP(j) = outs{j}.torque*P.rotor.Omega/(P.env.rho*A*Vtip_mps^3);
        FM(j) = figure_of_merit(CT(j),CP(j));
    end

    one = table(collective75_deg(k),CT_exp(k),CT(1),CT(2),CT(3),CT(4),CT(5), ...
        CP_exp(k),CP(1),CP(2),CP(3),CP(4),CP(5),FM_exp(k), ...
        FM(1),FM(2),FM(3),FM(4),FM(5), ...
        outs{1}.zFlap(1)*180/pi,outs{1}.zFlap(2)*180/pi,outs{1}.zFlap(3)*180/pi, ...
        'VariableNames',{'collective75_deg','CT_exp','CT_baseline','CT_nominalFullBeta', ...
        'CT_nominalHarmonicOnly','CT_reversedFullBeta','CT_reversedHarmonicOnly', ...
        'CP_exp','CP_baseline','CP_nominalFullBeta','CP_nominalHarmonicOnly', ...
        'CP_reversedFullBeta','CP_reversedHarmonicOnly','FM_exp','FM_baseline', ...
        'FM_nominalFullBeta','FM_nominalHarmonicOnly','FM_reversedFullBeta', ...
        'FM_reversedHarmonicOnly','beta0_baseline_deg','beta1c_baseline_deg', ...
        'beta1s_baseline_deg'});
    rows = [rows;one]; %#ok<AGROW>
end
writetable(rows,fullfile(outputDir,'XV15_DELTA3_PITCH_FLAP_MATLAB_DIAGNOSTIC.csv'));

maskAll = true(height(rows),1); maskHigh = rows.collective75_deg>=9;
metrics = table();
for rangeIndex = 1:2
    if rangeIndex==1; mask=maskAll; suffix='6to11'; else; mask=maskHigh; suffix='9to11'; end
    for j = 1:numel(modeName)
        key = matlab.lang.makeValidName(modeName{j});
        ctField = ['CT_' field_suffix(j)]; cpField = ['CP_' field_suffix(j)]; fmField = ['FM_' field_suffix(j)];
        metrics.(['CT_MAPE_' key '_' suffix '_pct']) = mape(rows.(ctField),rows.CT_exp,mask);
        metrics.(['CP_MAPE_' key '_' suffix '_pct']) = mape(rows.(cpField),rows.CP_exp,mask);
        metrics.(['FM_MAPE_' key '_' suffix '_pct']) = mape(rows.(fmField),rows.FM_exp,mask);
    end
end
writetable(metrics,fullfile(outputDir,'XV15_DELTA3_PITCH_FLAP_MATLAB_METRICS.csv'));

results = struct();
results.table = rows; results.metrics = metrics; results.KpfMagnitude = K;
results.preferredInterpretation = 'HARMONIC_GIMBAL_ONLY';
results.claimBoundary = ['XV15_DELTA3_MAGNITUDE_SCREEN_SIGN_CONVENTION_BOUNDED_' ...
    'HARMONIC_GIMBAL_PREFERRED_NO_OARF_FIT_NO_PRODUCTION_CHANGE'];
save(fullfile(outputDir,'XV15_DELTA3_PITCH_FLAP_RESULTS.mat'),'results');
end

function name = field_suffix(j)
names = {'baseline','nominalFullBeta','nominalHarmonicOnly', ...
    'reversedFullBeta','reversedHarmonicOnly'};
name = names{j};
end

function out = solve_case(P,theta75_deg,theta75Source_deg,scalarC81,Kpf,useFullBeta)
R=P.rotor.R; Omega=P.rotor.Omega; Vtip=Omega*R; rho=P.env.rho; A=pi*R^2;
r0=P.rotor.rootCut*R; edges=linspace(r0,R,P.rotor.nRadial+1);
r=0.5*(edges(1:end-1)+edges(2:end)); dr=diff(edges); x=r/R;
psi=((0:P.rotor.nAzimuth-1)*(2*pi/P.rotor.nAzimuth)).';
chord=xv15_metal_chord_m(x);
thetaBase=(theta75_deg+nasa_metal_twist_deg(x)-theta75Source_deg)*pi/180;
UT=Omega*r;
vi=sqrt(max(P.mass.m*P.env.g/2,1)/(2*rho*A));
z=P.rotor.flapInitial(:); converged=false; viError=Inf;
for iter=1:max(100,5*P.rotor.inducedMaxIter)
    [z,flapOK,flapNorm]=solve_flap(vi,z);
    if ~flapOK; break; end
    loads=blade_loads(vi,z);
    lambda1=-vi/max(Vtip,eps);
    CTiter=max(loads.T,0)/(0.5*rho*A*Vtip^2);
    viTarget=Vtip*CTiter/(4*max(abs(lambda1),1e-12));
    viNew=0.5*(vi+viTarget); viError=abs(viNew-vi)/max(1,abs(vi)); vi=viNew;
    if viError<1e-6 && flapNorm<=P.rotor.flapResidualTol; converged=true; break; end
end
loads=blade_loads(vi,z);
out=struct('thrust',loads.T,'torque',loads.Q,'inducedVelocity',vi, ...
    'zFlap',z,'converged',converged,'iterations',iter,'Kpf',Kpf, ...
    'useFullBeta',useFullBeta);

    function [zNow,ok,rn]=solve_flap(viNow,z0)
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

    function [res,scale]=flap_residual(zNow,viNow)
        L=blade_loads(viNow,zNow);
        gravity=-P.rotor.Sblade*P.env.g*cos(L.beta);
        inertial=P.rotor.Ib*L.betaDDot+P.rotor.Ib*Omega^2*L.beta;
        by=inertial-L.flapMomentByAzimuth-gravity;
        res=[mean(by);2*mean(by.*cos(psi));2*mean(by.*sin(psi))];
        scale=max([max(abs(L.flapMomentByAzimuth)),max(abs(gravity)),P.rotor.Ib*Omega^2*0.05,1]);
    end

    function L=blade_loads(viNow,zNow)
        beta=zNow(1)+zNow(2)*cos(psi)+zNow(3)*sin(psi);
        betaHarmonic=zNow(2)*cos(psi)+zNow(3)*sin(psi);
        betaDot=-Omega*(-zNow(2)*sin(psi)+zNow(3)*cos(psi));
        betaDDot=-Omega^2*(zNow(2)*cos(psi)+zNow(3)*sin(psi));
        if useFullBeta; betaForPitch=beta; else; betaForPitch=betaHarmonic; end
        theta=thetaBase+Kpf*betaForPitch;
        viField=viNow.*(1+cos(psi).*(r/R));
        UP=viField-betaDot.*r; W=hypot(UT,UP);
        phi=atan2(UP,max(abs(UT),1e-8)); alpha=theta-phi;
        CL=scalarC81.CLmax*tanh(scalarC81.liftSlope*(alpha-scalarC81.alpha0L_rad)/scalarC81.CLmax);
        CD=scalarC81.CD0+scalarC81.kCD*CL.^2; q=0.5*rho*W.^2;
        dL=q.*chord.*CL.*dr; dD=q.*chord.*CD.*dr;
        dT=dL.*cos(phi)-dD.*sin(phi); dH=dD.*cos(phi)+dL.*sin(phi);
        dQ=dH.*r; factor=P.rotor.Nb/P.rotor.nAzimuth;
        L.T=factor*sum(dT(:)); L.Q=factor*sum(dQ(:));
        L.flapMomentByAzimuth=sum(dT.*r,2); L.beta=beta; L.betaDDot=betaDDot;
    end
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
