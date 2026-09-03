function out = rotor_inflow_closure_large_angle_local(section,aeroFcn,opts)
%ROTOR_INFLOW_CLOSURE_LARGE_ANGLE_LOCAL Stahlhut-inspired local hover closure.
%
% Analysis-only component closure for axial/hover conditions.  It keeps the
% blade-element representation and replaces the induced-flow closure with a
% nonlinear, large-inflow-angle local solution based on the equation family
% used by Stahlhut and by Sosa Henriquez & Lendraitis (2024).
%
% Required section fields (row vectors, one value per radial element):
%   rRatio, y_m, dr_m, chord_m, theta_rad
% Scalar fields:
%   R_m, Omega_radps, Nb, rho_kgm3, aSound_mps, Vinf_mps
%
% aeroFcn signature:
%   [CL,CD,meta] = aeroFcn(alpha_rad,Mach,rRatio,chord_m)
%
% This function deliberately does not contain XV-15 target data and does
% not tune any coefficient to CT/CP/FM.  It is a generic rotor-component
% closure prototype whose present validity boundary is steady axial flow.

if nargin < 3, opts = struct(); end
opts = defaults(opts);

r = section.rRatio(:).';
y = section.y_m(:).';
dr = section.dr_m(:).';
c = section.chord_m(:).';
theta = section.theta_rad(:).';
N = numel(r);
if any([numel(y),numel(dr),numel(c),numel(theta)] ~= N)
    error('rotor_inflow_closure_large_angle_local:SizeMismatch', ...
        'All radial section arrays must have identical lengths.');
end

phi = nan(1,N); U = nan(1,N); CL = nan(1,N); CD = nan(1,N);
F = nan(1,N); KT = nan(1,N); KP = nan(1,N); rootResidual = nan(1,N);
alpha = nan(1,N); Mach = nan(1,N); vi = nan(1,N); swirl = nan(1,N);
status = repmat({'UNSOLVED'},1,N);

for j = 1:N
    [phi(j),state,status{j}] = solve_one(j);
    if ~strcmp(status{j},'CONVERGED')
        continue;
    end
    U(j) = state.U;
    CL(j) = state.CL; CD(j) = state.CD;
    F(j) = state.F; KT(j) = state.KT; KP(j) = state.KP;
    alpha(j) = theta(j)-phi(j);
    Mach(j) = U(j)/section.aSound_mps;
    vi(j) = U(j)*sin(phi(j))-section.Vinf_mps;
    swirl(j) = section.Omega_radps*y(j)-U(j)*cos(phi(j));
    rootResidual(j) = state.g;
end

valid = strcmp(status,'CONVERGED');
if any(valid)
    q = 0.5*section.rho_kgm3*U(valid).^2;
    dL = q.*c(valid).*CL(valid).*dr(valid);
    dD = q.*c(valid).*CD(valid).*dr(valid);
    dTperBlade = dL.*cos(phi(valid))-dD.*sin(phi(valid));
    dHperBlade = dL.*sin(phi(valid))+dD.*cos(phi(valid));
    dQperBlade = dHperBlade.*y(valid);
    dT = nan(1,N); dQ = nan(1,N);
    dT(valid) = section.Nb*dTperBlade;
    dQ(valid) = section.Nb*dQperBlade;
else
    dT = nan(1,N); dQ = nan(1,N);
end

out = struct();
out.phi_rad = phi;
out.alpha_rad = alpha;
out.U_mps = U;
out.vi_mps = vi;
out.swirl_mps = swirl;
out.CL = CL; out.CD = CD;
out.Mach = Mach;
out.F = F; out.KT = KT; out.KP = KP;
out.rootResidual = rootResidual;
out.status = status;
out.dT_N = dT; out.dQ_Nm = dQ;
out.thrust_N = sum(dT(valid));
out.torque_Nm = sum(dQ(valid));
out.allSectionsConverged = all(valid);
out.maxAbsRootResidual = max([abs(rootResidual(valid)),0]);
out.claimBoundary = ['STEADY_AXIAL_LARGE_ANGLE_LOCAL_CLOSURE_' ...
    'STAHLHUT_INSPIRED_NO_TARGET_FIT_NOT_NONLOCAL_WAKE'];

    function [phiSol,stateSol,stat] = solve_one(jj)
        grid = linspace(opts.phiMin_rad,opts.phiMax_rad,opts.bracketSamples);
        gv = nan(size(grid));
        states = cell(size(grid));
        for kk = 1:numel(grid)
            [gv(kk),states{kk}] = residual(grid(kk),jj);
        end
        finitePair = isfinite(gv(1:end-1)) & isfinite(gv(2:end));
        cross = find(finitePair & gv(1:end-1).*gv(2:end) <= 0,1,'first');
        if isempty(cross)
            phiSol = NaN; stateSol = struct(); stat = 'NO_POSITIVE_BRACKET'; return;
        end
        lo = grid(cross); hi = grid(cross+1);
        [glo,~] = residual(lo,jj);
        stateSol = states{cross};
        for it = 1:opts.bisectionMaxIter
            mid = 0.5*(lo+hi);
            [gm,sm] = residual(mid,jj);
            if ~isfinite(gm)
                phiSol = NaN; stateSol = struct(); stat = 'NONFINITE_RESIDUAL'; return;
            end
            if abs(gm) <= opts.rootTol || abs(hi-lo) <= opts.phiTol_rad
                phiSol = mid; stateSol = sm; stat = 'CONVERGED'; return;
            end
            if glo*gm <= 0
                hi = mid;
            else
                lo = mid; glo = gm;
            end
            stateSol = sm;
        end
        phiSol = 0.5*(lo+hi);
        [~,stateSol] = residual(phiSol,jj);
        stat = 'MAX_ITER_ACCEPTED';
    end

    function [g,s] = residual(ph,jj)
        s = local_state(ph,jj);
        if ~s.valid
            g = NaN; s.g = NaN; return;
        end
        sy = sign(ph); if sy == 0, sy = 1; end
        OmY = section.Omega_radps*y(jj);
        Vc = section.Vinf_mps;
        sigma = section.Nb*c(jj)/(pi*section.R_m);
        g = (OmY*sin(ph)-Vc*cos(ph))*sin(ph) - ...
            sy*sigma*s.CL*s.secgamma/(8*r(jj))* ...
            ((OmY/s.KT)*cos(ph+s.gamma) + ...
             (Vc/s.KP)*sin(ph+s.gamma));
        s.g = g;
    end

    function s = local_state(ph,jj)
        s = struct('valid',false,'U',NaN,'CL',NaN,'CD',NaN, ...
            'gamma',NaN,'secgamma',NaN,'F',NaN,'KT',NaN,'KP',NaN,'g',NaN);
        OmY = section.Omega_radps*y(jj);
        Uj = max(OmY/max(cos(ph),0.15),1e-6);
        for ii = 1:opts.innerMaxIter
            a = theta(jj)-ph;
            M = Uj/section.aSound_mps;
            [cl,cd] = aeroFcn(a,M,r(jj),c(jj));
            if ~isfinite(cl) || ~isfinite(cd), return; end
            % tan(gamma)=CD/CL. atan2 retains the correct force angle.
            gamma = atan2(cd,max(cl,opts.minPositiveCL));
            secg = 1/max(cos(gamma),opts.minCosGamma);
            sinp = max(abs(sin(ph)),opts.minSinPhi);
            fTip = (section.Nb/2)*(1-r(jj))/(max(r(jj),eps)*sinp);
            Fj = (2/pi)*acos(exp(-max(fTip,0)));
            Fj = min(max(Fj,opts.minF),1);
            KTj = 1-(1-Fj)*cos(ph);
            KPj = 1-(1-Fj)*sin(ph);
            KTj = max(KTj,opts.minK); KPj = max(KPj,opts.minK);
            sigma = section.Nb*c(jj)/(pi*section.R_m);
            B2 = cos(ph) + sigma*cl*secg/(8*r(jj)*KPj)* ...
                (sin(ph+gamma)/sinp);
            if ~isfinite(B2) || B2 <= opts.minB2, return; end
            Unew = OmY/B2;
            if ~isfinite(Unew) || Unew <= 0, return; end
            if abs(Unew-Uj)/max(Uj,1) < opts.innerTol
                Uj = Unew; break;
            end
            Uj = (1-opts.innerRelax)*Uj + opts.innerRelax*Unew;
        end
        a = theta(jj)-ph;
        M = Uj/section.aSound_mps;
        [cl,cd] = aeroFcn(a,M,r(jj),c(jj));
        gamma = atan2(cd,max(cl,opts.minPositiveCL));
        secg = 1/max(cos(gamma),opts.minCosGamma);
        sinp = max(abs(sin(ph)),opts.minSinPhi);
        fTip = (section.Nb/2)*(1-r(jj))/(max(r(jj),eps)*sinp);
        Fj = min(max((2/pi)*acos(exp(-max(fTip,0))),opts.minF),1);
        KTj = max(1-(1-Fj)*cos(ph),opts.minK);
        KPj = max(1-(1-Fj)*sin(ph),opts.minK);
        s.valid = all(isfinite([Uj,cl,cd,gamma,secg,Fj,KTj,KPj]));
        s.U=Uj; s.CL=cl; s.CD=cd; s.gamma=gamma; s.secgamma=secg;
        s.F=Fj; s.KT=KTj; s.KP=KPj;
    end
end

function opts = defaults(opts)
D = struct('phiMin_rad',0.05*pi/180,'phiMax_rad',80*pi/180, ...
    'bracketSamples',321,'bisectionMaxIter',80,'rootTol',1e-8, ...
    'phiTol_rad',1e-9,'innerMaxIter',40,'innerTol',1e-8,'innerRelax',0.35, ...
    'minPositiveCL',1e-5,'minCosGamma',1e-3,'minSinPhi',1e-5, ...
    'minF',1e-4,'minK',1e-4,'minB2',1e-4);
fn = fieldnames(D);
for k=1:numel(fn)
    if ~isfield(opts,fn{k}) || isempty(opts.(fn{k})), opts.(fn{k})=D.(fn{k}); end
end
end
