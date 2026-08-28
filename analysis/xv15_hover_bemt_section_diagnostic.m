function out = xv15_hover_bemt_section_diagnostic(P, collectiveRad, sectionMode, scalarC81)
%XV15_HOVER_BEMT_SECTION_DIAGNOSTIC Hover-only mirror of production BEMT.
%
% Controlled error-attribution helper. The induced-velocity update, NUAA
% Eq. (12) inflow, first-harmonic flapping solve, blade-element force
% resolution and momentum closure mirror model/rotor_model_bemt.m for the
% validation call x=zeros(9,1), betaM=0, side=-1, cgShift=zeros(3,1).
% Only the section-aerodynamic closure changes between modes:
%   GENERIC_LOW_ORDER
%   SCALAR_C81_LOW_ORDER
%   SPANWISE_C81_LOCAL_MACH
%
% Diagnostic only; not a second production rotor model.

if nargin < 4
    scalarC81 = [];
end
sectionMode = upper(char(sectionMode));
validModes = {'GENERIC_LOW_ORDER','SCALAR_C81_LOW_ORDER', ...
    'SPANWISE_C81_LOCAL_MACH'};
if ~ismember(sectionMode, validModes)
    error('xv15_hover_bemt_section_diagnostic:UnknownMode', ...
        'Unknown section mode: %s', sectionMode);
end
if strcmp(sectionMode,'SCALAR_C81_LOW_ORDER') && isempty(scalarC81)
    error('xv15_hover_bemt_section_diagnostic:MissingScalarC81', ...
        'SCALAR_C81_LOW_ORDER requires the C81 scalar reduction struct.');
end

R = P.rotor.R;
Omega = P.rotor.Omega;
tipSpeed = Omega*R;
A = pi*R^2;
rho = P.env.rho;

r0 = P.rotor.rootCut*R;
rEdges = linspace(r0,R,P.rotor.nRadial+1);
rMid = 0.5*(rEdges(1:end-1)+rEdges(2:end));
dr = diff(rEdges);
psi = ((0:P.rotor.nAzimuth-1)*(2*pi/P.rotor.nAzimuth)).';

twist = P.rotor.twistTip*(rMid-r0)/max(R-r0,eps);
thetaBlade = collectiveRad + twist;
UT = Omega*rMid;

if isfield(P.env,'aSound') && isfinite(P.env.aSound) && P.env.aSound > 0
    aSound = P.env.aSound;
else
    aSound = 340.0;
end

vi = sqrt(max(P.mass.m*P.env.g/2,1)/(2*rho*A));
zFlap = P.rotor.flapInitial(:);
if numel(zFlap) ~= 3
    error('P.rotor.flapInitial must contain [beta0; beta1c; beta1s].');
end

coupledConverged = false;
viError = Inf;
flapInfo = struct('converged',false,'residualNorm',Inf);
positiveThrustGuardEverActive = false;

for iter = 1:P.rotor.inducedMaxIter
    [zFlap,flapInfo] = solve_flap(vi,zFlap);
    if ~flapInfo.converged
        out = failed_out('FLAP_NOT_CONVERGED',iter,vi,zFlap,flapInfo);
        return;
    end

    loads = blade_loads(vi,zFlap);
    lambda1 = -vi/max(tipSpeed,eps);
    CTiter = max(loads.T,0)/(0.5*rho*A*tipSpeed^2);
    denomEq13Used = max(abs(lambda1),1.0e-12);
    viTarget = tipSpeed*CTiter/(4*denomEq13Used);

    viNew = 0.5*(vi+viTarget);
    viError = abs(viNew-vi)/max(1,abs(vi));
    positiveThrustGuardEverActive = positiveThrustGuardEverActive || loads.T < 0;
    vi = viNew;

    if viError < P.rotor.inducedTol && ...
            flapInfo.residualNorm <= P.rotor.flapResidualTol
        coupledConverged = true;
        break;
    end
end

if ~coupledConverged
    out = failed_out('COUPLED_SOLVE_NOT_CONVERGED',iter,vi,zFlap,flapInfo);
    return;
end

loads = blade_loads(vi,zFlap);
lambda1Final = -vi/max(tipSpeed,eps);
momentumThrust = 2*rho*A*tipSpeed*vi*abs(lambda1Final);
closureResidual = loads.T-momentumThrust;
closureScale = max([abs(loads.T),abs(momentumThrust),1]);
closureResidualRelative = abs(closureResidual)/closureScale;
closureTolerance = 2.0e-4;

physicalBranchSupported = loads.T > 0;
closureResidualSatisfied = closureResidualRelative <= closureTolerance;
physicalConverged = coupledConverged && physicalBranchSupported && ...
    closureResidualSatisfied;

if loads.T < 0
    physicalStatus = 'UNSUPPORTED_NEGATIVE_THRUST_BRANCH';
elseif loads.T == 0
    physicalStatus = 'UNSUPPORTED_ZERO_THRUST_BRANCH';
elseif ~closureResidualSatisfied
    physicalStatus = 'INDUCED_CLOSURE_RESIDUAL_NOT_SATISFIED';
else
    physicalStatus = 'PHYSICAL_CONVERGED';
end

out = struct();
out.sectionMode = sectionMode;
out.thrust = loads.T;
out.torque = loads.Q;
out.inducedVelocity = vi;
out.iterations = iter;
out.zFlap = zFlap;
out.flap = flapInfo;
out.inducedVelocityError = viError;
out.inducedMomentumThrust = momentumThrust;
out.inducedClosureResidual = closureResidual;
out.inducedClosureResidualRelative = closureResidualRelative;
out.inducedClosureResidualRelativeTolerance = closureTolerance;
out.physicalBranchSupported = physicalBranchSupported;
out.closureResidualSatisfied = closureResidualSatisfied;
out.physicalConverged = physicalConverged;
out.physicalStatus = physicalStatus;
out.positiveThrustGuardEverActive = positiveThrustGuardEverActive;
out.alphaMin_deg = min(loads.alphaBlade(:))*180/pi;
out.alphaMax_deg = max(loads.alphaBlade(:))*180/pi;
out.machMin = min(loads.Mach(:));
out.machMax = max(loads.Mach(:));
out.c81AlphaClampCount = loads.sectionMeta.alphaClampCount;
out.c81MachClampCount = loads.sectionMeta.machClampCount;
out.claimBoundary = ['HOVER_DIAGNOSTIC_MIRROR_ONLY_SECTION_AERO_VARIED_' ...
    'NO_OARF_PARAMETER_FIT'];

    function [z,info] = solve_flap(viMean,z0)
        z = z0(:);
        info = struct('converged',false,'iterations',0, ...
            'residual',NaN(3,1),'residualNorm',Inf,'scale',NaN, ...
            'exitStatus','not_started');

        for k = 1:P.rotor.flapMaxIter
            [res,aux] = flap_residual(z,viMean);
            rn = res/aux.scale;
            nR = norm(rn);
            info.iterations = k;
            info.residual = res;
            info.residualNorm = nR;
            info.scale = aux.scale;

            if nR <= P.rotor.flapResidualTol
                info.converged = true;
                info.exitStatus = 'converged';
                return;
            end

            J = zeros(3,3);
            for jj = 1:3
                h = P.rotor.flapJacobianStep*max(1,abs(z(jj)));
                zp = z; zm = z;
                zp(jj) = zp(jj)+h;
                zm(jj) = zm(jj)-h;
                rp = flap_residual(zp,viMean);
                rm = flap_residual(zm,viMean);
                J(:,jj) = (rp/aux.scale-rm/aux.scale)/(2*h);
            end

            if ~all(isfinite(J(:))) || rcond(J.'*J) < 1e-14
                info.exitStatus = 'singular_jacobian';
                return;
            end

            reg = P.rotor.flapNewtonRegularization;
            dz = -(J.'*J + reg*eye(3))\(J.'*rn);
            alphaStep = 1.0;
            accepted = false;
            for trial = 1:P.rotor.flapLineSearchMaxIter
                zc = z+alphaStep*dz;
                betaCheck = zc(1)+zc(2)*cos(psi)+zc(3)*sin(psi);
                validState = all(isfinite(zc)) && ...
                    max(abs(betaCheck)) < P.rotor.flapDivergenceAngle;
                if validState
                    [rc,auxc] = flap_residual(zc,viMean);
                    if norm(rc/auxc.scale) < nR
                        z = zc;
                        accepted = true;
                        break;
                    end
                end
                alphaStep = alphaStep*P.rotor.flapNewtonDamping;
            end
            if ~accepted
                info.exitStatus = 'line_search_failed';
                return;
            end
        end

        [res,aux] = flap_residual(z,viMean);
        info.iterations = P.rotor.flapMaxIter;
        info.residual = res;
        info.residualNorm = norm(res/aux.scale);
        info.scale = aux.scale;
        info.exitStatus = 'max_iter';
    end

    function [res,aux] = flap_residual(z,viMean)
        ll = blade_loads(viMean,z);
        gravityMoment = -P.rotor.Sblade*P.env.g*cos(ll.beta);
        inertialRestoring = P.rotor.Ib*ll.betaDDot + ...
            P.rotor.Ib*Omega^2*ll.beta;
        residualByAz = inertialRestoring-ll.flapMomentByAzimuth- ...
            gravityMoment;
        res = [mean(residualByAz); ...
               2*mean(residualByAz.*cos(psi)); ...
               2*mean(residualByAz.*sin(psi))];
        aux.scale = max([max(abs(ll.flapMomentByAzimuth)), ...
            max(abs(gravityMoment)),P.rotor.Ib*Omega^2*0.05,1]);
    end

    function ll = blade_loads(viMean,z)
        betaLocal = z(1)+z(2)*cos(psi)+z(3)*sin(psi);
        betaDotLocal = -Omega*(-z(2)*sin(psi)+z(3)*cos(psi));
        betaDDotLocal = -Omega^2*(z(2)*cos(psi)+z(3)*sin(psi));

        viField = viMean.*(1+cos(psi).*(rMid/R));
        UP = viField-betaDotLocal.*rMid;
        W = hypot(UT,UP);
        phiInflow = atan2(UP,max(abs(UT),1e-8));
        alphaBlade = thetaBlade-phiInflow;
        MachLocal = W/aSound;

        if strcmp(sectionMode,'GENERIC_LOW_ORDER')
            CL = P.rotor.CLmax*tanh( ...
                P.rotor.liftSlope*alphaBlade/P.rotor.CLmax);
            CD = P.rotor.CD0+P.rotor.kCD*CL.^2;
            sm = struct('alphaClampCount',0,'machClampCount',0);
        elseif strcmp(sectionMode,'SCALAR_C81_LOW_ORDER')
            CL = scalarC81.CLmax*tanh( ...
                scalarC81.liftSlope*(alphaBlade-scalarC81.alpha0L_rad) / ...
                scalarC81.CLmax);
            CD = scalarC81.CD0+scalarC81.kCD*CL.^2;
            sm = struct('alphaClampCount',0,'machClampCount',0);
        else
            [CL,CD,sm] = xv15_c81_section_lookup( ...
                alphaBlade,MachLocal,rMid/R);
        end

        qElem = 0.5*rho*W.^2;
        dL = qElem*P.rotor.chord.*CL.*dr;
        dD = qElem*P.rotor.chord.*CD.*dr;
        dT = dL.*cos(phiInflow)-dD.*sin(phiInflow);
        dH = dD.*cos(phiInflow)+dL.*sin(phiInflow);
        dQ = dH.*rMid;

        factor = P.rotor.Nb/P.rotor.nAzimuth;
        ll.T = factor*sum(dT(:));
        ll.Q = factor*sum(dQ(:));
        ll.flapMomentByAzimuth = sum(dT.*rMid,2);
        ll.beta = betaLocal;
        ll.betaDDot = betaDDotLocal;
        ll.alphaBlade = alphaBlade;
        ll.Mach = MachLocal;
        ll.sectionMeta = sm;
    end

    function fo = failed_out(status,iteration,viNow,zNow,flapNow)
        fo = struct();
        fo.sectionMode = sectionMode;
        fo.thrust = NaN; fo.torque = NaN;
        fo.inducedVelocity = viNow; fo.iterations = iteration;
        fo.zFlap = zNow; fo.flap = flapNow;
        fo.inducedVelocityError = Inf;
        fo.inducedMomentumThrust = NaN;
        fo.inducedClosureResidual = NaN;
        fo.inducedClosureResidualRelative = NaN;
        fo.inducedClosureResidualRelativeTolerance = 2.0e-4;
        fo.physicalBranchSupported = false;
        fo.closureResidualSatisfied = false;
        fo.physicalConverged = false;
        fo.physicalStatus = status;
        fo.positiveThrustGuardEverActive = false;
        fo.alphaMin_deg = NaN; fo.alphaMax_deg = NaN;
        fo.machMin = NaN; fo.machMax = NaN;
        fo.c81AlphaClampCount = NaN; fo.c81MachClampCount = NaN;
        fo.claimBoundary = ['HOVER_DIAGNOSTIC_MIRROR_ONLY_SECTION_AERO_VARIED_' ...
            'NO_OARF_PARAMETER_FIT'];
    end
end
